from fastapi import (
    FastAPI,
    UploadFile,
    File,
    Body,
    HTTPException,
    BackgroundTasks,
)
from fastapi.responses import FileResponse
import os
import json
import logging
from typing import Literal
from pydantic import BaseModel

from app.services import generator, srs, concept_map, exporter, tts
from app.utils.llm import ask_llm
from app.models import ReviewInput, ExportInput

class StudyRequest(BaseModel):
    """Request model for study mode generation."""

    text: str
    mode: Literal[
        "memorization",
        "deep_understanding",
        "contextual_association",
        "interactive_evaluation",
    ]

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

MAX_UPLOAD_SIZE = 5 * 1024 * 1024  # 5 MB

app = FastAPI()


@app.post('/upload-content', tags=["Content"])
async def upload_content(file: UploadFile = File(...)):
    """Extract text from an uploaded file."""
    try:
        file.file.seek(0, os.SEEK_END)
        size = file.file.tell()
        file.file.seek(0)
        if size > MAX_UPLOAD_SIZE:
            raise HTTPException(status_code=400, detail="File too large (max 5MB)")
        content_type = (file.content_type or "").lower()
        if content_type.startswith("audio/"):
            text = generator.transcribe_audio(file)
            return {"text": text}
        if content_type.startswith("video/"):
            text = generator.transcribe_video(file)
            return {"text": text}

        return generator.generate_course(file)
    except HTTPException as exc:
        raise exc
    except Exception as exc:
        logger.exception("Failed to process upload: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/analyze', tags=["Analysis"])
def analyze_text(text: str = Body(..., embed=True)):
    """Return summary and topics for the given text using the LLM."""
    prompt = (
        "Analyze the following text and respond only in JSON with the keys:\n"
        "{\n"
        '  "summary": str,\n'
        '  "concept_map": [str, ...],\n'
        '  "flashcards": [{"term": str, "definition": str}],\n'
        '  "quiz": [{"question": str, "options": [str, ...], "answer": str}],\n'
        '  "spaced_repetition": [str, ...],\n'
        '  "progress": {"completion": float, "masteryLevel": str}\n'
        "}\n"
        "Include key points in your analysis.\n\n" + text
    )
    try:
        result = ask_llm(prompt)
        try:
            data = json.loads(result)
        except Exception:
            data = {"summary": result}

        return {
            "summary": data.get("summary", ""),
            "concept_map": data.get("concept_map")
            or data.get("conceptMap", []),
            "flashcards": data.get("flashcards", []),
            "quiz": data.get("quiz") or data.get("quizQuestions", []),
            "spaced_repetition": data.get("spaced_repetition")
            or data.get("spacedRepetition", []),
            "progress": data.get("progress", {"completion": 0.0, "masteryLevel": ""}),
        }
    except Exception as exc:
        logger.exception("Analysis failed: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/study-mode', tags=["Study"])
def study_mode(data: StudyRequest):
    """Generate study materials in the requested mode."""
    if data.mode == "memorization":
        prompt = (
            "Create flashcard question-answer pairs as JSON in the form "
            "{'flashcards': [{'question': str, 'answer': str}]} for the following text:\n\n"
            + data.text
        )
        try:
            result = ask_llm(prompt)
            try:
                payload = json.loads(result)
                if "flashcards" not in payload and "cards" in payload:
                    payload = {"flashcards": payload.get("cards")}
                return payload
            except Exception:
                return {"flashcards": result}
        except Exception as exc:
            logger.exception("Flashcard generation failed: %s", exc)
            raise HTTPException(status_code=500, detail="Internal server error")

    if data.mode == "deep_understanding":
        try:
            return {"conceptMap": concept_map.generate_concept_map(data.text)}
        except Exception as exc:
            logger.exception("Concept map generation failed: %s", exc)
            raise HTTPException(status_code=500, detail="Internal server error")

    if data.mode == "contextual_association":
        prompt = (
            "Generate contextual practice exercises as JSON in the form "
            "{'contextualExercises': [...]} for the following text:\n\n" + data.text
        )
        try:
            result = ask_llm(prompt)
            try:
                payload = json.loads(result)
                if "contextualExercises" not in payload and "exercises" in payload:
                    payload = {"contextualExercises": payload.get("exercises")}
                return payload
            except Exception:
                return {"contextualExercises": result}
        except Exception as exc:
            logger.exception("Exercise generation failed: %s", exc)
            raise HTTPException(status_code=500, detail="Internal server error")

    if data.mode == "interactive_evaluation":
        prompt = (
            "Generate quiz questions as JSON in the form "
            "{'evaluationQuestions': [...]} for the following text:\n\n" + data.text
        )
        try:
            result = ask_llm(prompt)
            try:
                payload = json.loads(result)
                if "evaluationQuestions" not in payload and "exercises" in payload:
                    payload = {"evaluationQuestions": payload.get("exercises")}
                return payload
            except Exception:
                return {"evaluationQuestions": result}
        except Exception as exc:
            logger.exception("Exercise generation failed: %s", exc)
            raise HTTPException(status_code=500, detail="Internal server error")

    raise HTTPException(status_code=400, detail="Invalid study mode")


@app.post('/review/{card_id}', tags=["Flashcards"])
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


@app.post('/speak', tags=["Speech"])
def speak(data: str = Body(..., embed=True)):
    """Convert text to speech and return an MP3 file."""
    try:
        path = tts.text_to_speech(data)
        return FileResponse(
            path,
            media_type='audio/mpeg',
            background=BackgroundTask(os.remove, path),
        )
    except Exception as exc:
        logger.exception("Text-to-speech failed: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/export', tags=["Export"])
def export_content(data: ExportInput = Body(...)):
    """Export content to Markdown, text or PDF."""
    try:
        if data.fmt == 'pdf':
            path = exporter.export_to_pdf_file(data.content)
            return FileResponse(
                path,
                media_type='application/pdf',
                background=BackgroundTask(os.remove, path),
            )
        result = exporter.export_content(data.content, data.fmt)
        return {'content': result}
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.exception("Failed to export content: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")
