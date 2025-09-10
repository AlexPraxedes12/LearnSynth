from fastapi import (
    FastAPI,
    UploadFile,
    File,
    Body,
    HTTPException,
    BackgroundTasks,
    Request,
)
import os
import logging
from pathlib import Path

# Ensure environment variables are loaded before using LLM utilities
try:  # pragma: no cover - optional in tests
    from app import config as _config  # type: ignore  # noqa: F401
except Exception:  # pragma: no cover - fallback when app is a stub
    import importlib.util

    _config_path = Path(__file__).resolve().parent / "app" / "config.py"
    spec = importlib.util.spec_from_file_location("app.config", _config_path)
    _config = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(_config)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("learnsynth")

token = os.getenv("REPLICATE_API_TOKEN")
key = os.getenv("REPLICATE_API_KEY")

# Solo para DEBUG y siempre enmascarado
if os.getenv("DEBUG_LOG_TOKENS") == "1":
    def _mask(v: str, p=4, s=2):
        return "(unset)" if not v else f"{v[:p]}…{v[-s:]}"
    logger.debug("REPLICATE_API_TOKEN=%s", _mask(token))
    logger.debug("REPLICATE_API_KEY=%s", _mask(key))

# Info seguro: solo presencia (nunca valores)
logger.info("REPLICATE_API_TOKEN is %s", "set" if token else "missing")
logger.info("REPLICATE_API_KEY is %s", "set" if key else "missing")
from fastapi.responses import FileResponse
from app.middleware.normalize_json import normalize_json_middleware

try:  # pragma: no cover - optional dependency
    from starlette.responses import JSONResponse
except Exception:  # pragma: no cover - fallback for tests

    class JSONResponse(dict):  # type: ignore
        def __init__(self, content, status_code=200):
            super().__init__(content=content, status_code=status_code)


import asyncio
import json
from fastapi.middleware.cors import CORSMiddleware

try:  # pragma: no cover - optional dependency
    from sse_starlette.sse import EventSourceResponse
except Exception:  # pragma: no cover - optional
    EventSourceResponse = None

from app.services import generator, srs, concept_map, exporter, tts
try:
    from app.utils.llm import (
        ask_llm,
        generate_items,
        make_deep_prompts,
        build_deep_prompts,
        _dedup_flashcards,
        validate_quiz_item,
    )
except Exception:  # pragma: no cover - tests may stub without new funcs
    from app.utils.llm import (
        ask_llm,
        generate_items,
        make_deep_prompts,
        build_deep_prompts,
    )
    _dedup_flashcards = None  # type: ignore
    validate_quiz_item = None  # type: ignore

try:
    from app.utils.llm import _normalize_provider
except Exception:  # pragma: no cover - test stubs may omit

    def _normalize_provider(name: str) -> str:  # type: ignore
        return (name or "").strip().lower()


from app.models import ReviewInput, ExportInput
from services import llm_service

logger.info("FLASHCARD_TARGET=%s", os.getenv("FLASHCARD_TARGET"))
logger.info("QUIZ_TARGET=%s", os.getenv("QUIZ_TARGET"))
MAX_MEDIA_BYTES = int(
    os.getenv("MAX_MEDIA_BYTES", str(100 * 1024 * 1024))
)  # 100 MB default

app = FastAPI(title="LearnSynth API")


def _ensure_list(v):
    if isinstance(v, list):
        return v
    if v is None:
        return []
    return [v]


@app.middleware("http")
async def _normalize_json(request: Request, call_next):
    return await normalize_json_middleware(request, call_next)


# Restrict CORS to known front-end origins
ALLOWED_ORIGINS = [
    "https://www.learnsynth.com",
    "https://learnsynth.com",
    "http://localhost:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


@app.post("/llm/generate")
async def llm_generate(body: dict):
    """Unified LLM generation endpoint with optional streaming."""
    prompt = body.get("prompt") or ""
    if not prompt:
        raise HTTPException(400, "prompt vacío")

    max_tokens = int(body.get("max_tokens", 1536))
    temperature = float(body.get("temperature", 0.2))
    stream = bool(body.get("stream", True))

    if stream:
        if not EventSourceResponse:
            raise HTTPException(500, "SSE support not installed")

        async def sse():
            try:
                async for piece in llm_service.stream(
                    prompt, max_tokens=max_tokens, temperature=temperature
                ):
                    if piece:
                        yield f"data: {json.dumps({'delta': piece})}\n\n"
                        await asyncio.sleep(0)
                yield "data: [DONE]\n\n"
            except Exception as e:  # pragma: no cover - best effort
                yield f"data: {json.dumps({'error': str(e)})}\n\n"

        return EventSourceResponse(sse(), media_type="text/event-stream")

    try:
        text = await llm_service.complete(
            prompt, max_tokens=max_tokens, temperature=temperature
        )
        return JSONResponse({"text": text})
    except Exception as e:  # pragma: no cover - best effort
        raise HTTPException(500, str(e))


@app.post("/upload-content", tags=["Content"])
async def upload_content(file: UploadFile = File(...)):
    """Extract text from an uploaded file."""
    try:
        file.file.seek(0, os.SEEK_END)
        size = file.file.tell()
        file.file.seek(0)
        logger.info(
            "upload_content: name=%s content_type=%s size=%d",
            file.filename,
            file.content_type,
            size,
        )
        if size > MAX_MEDIA_BYTES:
            limit_mb = MAX_MEDIA_BYTES // (1024 * 1024)
            raise HTTPException(status_code=400, detail=f"File exceeds {limit_mb} MB limit")
        content_type = (file.content_type or "").lower()
        ext = os.path.splitext(file.filename or "")[1].lower()

        if content_type.startswith("audio/") or ext in [
            ".mp3",
            ".m4a",
            ".wav",
            ".flac",
            ".ogg",
            ".aac",
        ]:
            text = generator.transcribe_audio(file)
            return {"text": text}

        if content_type.startswith("video/") or ext in [
            ".mp4",
            ".mkv",
            ".mov",
            ".avi",
            ".webm",
        ]:
            text = generator.transcribe_video(file)
            return {"text": text}
        # else: document (PDF or text)
        data = await file.read()
        if ext.endswith('.txt') or 'text' in content_type:
            try:
                contents = data.decode('utf-8')
            except UnicodeDecodeError:
                try:
                    contents = data.decode('latin-1')
                except UnicodeDecodeError:
                    contents = data.decode('utf-8', errors='ignore')
        elif ext == '.pdf' or 'pdf' in content_type:
            contents = generator.extract_text_from_pdf(data)
        else:
            raise HTTPException(status_code=400, detail='Only .txt or .pdf files are supported')
        return {"text": contents}
    except HTTPException as exc:
        raise exc
    except Exception as exc:
        logger.exception("Failed to process upload: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/analyze", tags=["Analysis"])
async def analyze_text(payload: dict = Body(...)):
    try:
        text = (payload.get("text") or "").strip()
        provider = payload.get("llm_provider") or "oss"
        provider = _normalize_provider(provider)
        deep_prompts = build_deep_prompts(provider) or []
        if not text:
            return {
                "ok": False,
                "error": "empty text",
                "transcript": "",
                "summary": "",
                "deep_prompts": [],
                "concept_map": {},
                "quiz": [],
                "tags": [],
            }, 200

        async def _summary():
            return await asyncio.to_thread(ask_llm, f"Summarize:\n\n{text}")

        async def _concept():
            return await asyncio.to_thread(concept_map.generate_concept_map, text)

        async def _deep():
            return await asyncio.to_thread(make_deep_prompts, text)

        async def _quiz():
            items = await asyncio.to_thread(generate_items, text)
            return items.get("quiz", [])

        tasks = [_summary(), _concept(), _deep(), _quiz()]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        summary, cmap, deep, quiz = None, None, None, None
        errors = []
        for i, r in enumerate(results):
            if isinstance(r, Exception):
                errors.append(f"task_{i}: {r}")
            else:
                if i == 0:
                    summary = r
                elif i == 1:
                    cmap = r
                elif i == 2:
                    deep = r
                elif i == 3:
                    quiz = r

        deep_prompts_raw = _ensure_list(deep) or deep_prompts
        deep_prompts = []
        for item in deep_prompts_raw:
            if isinstance(item, dict):
                p = (item.get("prompt") or item.get("text") or "").strip()
                if not p:
                    continue
                obj = {"prompt": p}
                h = (item.get("hint") or item.get("explanation") or "").strip()
                if h:
                    obj["hint"] = h
                deep_prompts.append(obj)
            elif isinstance(item, str) and item.strip():
                deep_prompts.append({"prompt": item.strip(), "hint": ""})

        return {
            "ok": True,
            "transcript": text,
            "summary": summary or "",
            "deep_prompts": deep_prompts,
            "concept_map": cmap or {},
            "quiz": quiz or [],
            "tags": [],
            "errors": errors,
        }
    except Exception as e:
        logger.exception("analyze failed")
        return {
            "ok": False,
            "error": str(e),
            "transcript": "",
            "summary": "",
            "tags": [],
            "deep_prompts": [],
        }


@app.post("/study-mode", tags=["Study"])
async def study_mode(payload: dict = Body(...)):
    return await analyze_text(payload)


@app.get("/health")
def health():
    return {"ok": True, "provider": os.getenv("LLM_PROVIDER", "")}


@app.post("/review/{card_id}", tags=["Flashcards"])
def review_flashcard(card_id: str, review: ReviewInput = Body(...)):
    """Update spaced repetition progress for a flashcard."""
    try:
        updated = srs.update_flashcard(card_id, review.feedback)
        if not updated:
            raise HTTPException(status_code=404, detail="Card not found")
        return updated
    except HTTPException as exc:
        raise exc
    except Exception as exc:
        logger.exception("Failed to update flashcard %s: %s", card_id, exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/speak", tags=["Speech"])
def speak(data: str = Body(..., embed=True)):
    """Convert text to speech and return an MP3 file."""
    try:
        path = tts.text_to_speech(data)
        return FileResponse(
            path,
            media_type="audio/mpeg",
            background=BackgroundTask(os.remove, path),
        )
    except Exception as exc:
        logger.exception("Text-to-speech failed: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post("/export", tags=["Export"])
def export_content(data: ExportInput = Body(...)):
    """Export content to Markdown, text or PDF."""
    try:
        if data.fmt == "pdf":
            path = exporter.export_to_pdf_file(data.content)
            return FileResponse(
                path,
                media_type="application/pdf",
                background=BackgroundTask(os.remove, path),
            )
        result = exporter.export_content(data.content, data.fmt)
        return {"content": result}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("Failed to export content: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")
