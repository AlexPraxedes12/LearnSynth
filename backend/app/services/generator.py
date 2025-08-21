import os, logging, tempfile, subprocess, shlex
from fastapi import UploadFile, File, HTTPException
from io import BytesIO
import fitz  # PyMuPDF
from pdf2image import convert_from_bytes
import pytesseract
from openai import OpenAI

from app.utils.llm import (
    ask_llm,
    split_text_into_chunks,
    truncate_text_to_tokens,
    estimate_tokens,
    MAX_MODEL_TOKENS,
)

logger = logging.getLogger(__name__)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")
OPENAI_TRANSCRIBE_MODEL = os.getenv("OPENAI_TRANSCRIBE_MODEL", "whisper-1")
MAX_MEDIA_BYTES = int(os.getenv("MAX_MEDIA_BYTES", str(100 * 1024 * 1024)))  # 100MB default

client = OpenAI(api_key=OPENAI_API_KEY, base_url=OPENAI_BASE_URL)
logger.info("Transcription model=%s base_url=%s", OPENAI_TRANSCRIBE_MODEL, OPENAI_BASE_URL)
logger.info("MAX_MEDIA_BYTES=%s", MAX_MEDIA_BYTES)


def _ensure_size_ok(upload_file):
    # Works with FastAPI UploadFile
    upload_file.file.seek(0, os.SEEK_END)
    size = upload_file.file.tell()
    upload_file.file.seek(0)
    if size > MAX_MEDIA_BYTES:
        logger.info("File too large: %s bytes", size)
        raise HTTPException(status_code=400, detail="File too large")


def _extract_audio_to_tmp(video_upload_file, ext=".mp3"):
    # Requires ffmpeg in PATH (already in Docker image)
    with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as out:
        out_path = out.name
    with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as src:
        src_path = src.name
        video_upload_file.file.seek(0)
        src.write(video_upload_file.file.read())
    cmd = f'ffmpeg -y -i {shlex.quote(src_path)} -vn -ac 1 -ar 16000 -b:a 64k {shlex.quote(out_path)}'
    subprocess.run(shlex.split(cmd), check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return out_path


def transcribe_audio(file: UploadFile = File(...)) -> str:
    _ensure_size_ok(file)
    try:
        file.file.seek(0)
        resp = client.audio.transcriptions.create(
            model=OPENAI_TRANSCRIBE_MODEL,
            file=file.file
        )
        text = getattr(resp, "text", None) or (resp.get("text") if isinstance(resp, dict) else None)
        if not text:
            raise RuntimeError("Empty transcription")
        return text.strip()
    except Exception as exc:
        logger.exception("Transcription failed")
        raise HTTPException(status_code=500, detail="Transcription failed")


def transcribe_video(file: UploadFile = File(...)) -> str:
    _ensure_size_ok(file)
    try:
        audio_path = _extract_audio_to_tmp(file, ext=".mp3")
        with open(audio_path, "rb") as fh:
            resp = client.audio.transcriptions.create(model=OPENAI_TRANSCRIBE_MODEL, file=fh)
        text = getattr(resp, "text", None) or (resp.get("text") if isinstance(resp, dict) else None)
        if not text:
            raise RuntimeError("Empty transcription")
        return text.strip()
    except Exception:
        logger.exception("Transcription failed")
        raise HTTPException(status_code=500, detail="Transcription failed")


def extract_text_with_ocr(pdf_data: bytes) -> str:
    """Extract text from a PDF using OCR in Spanish."""
    pages = convert_from_bytes(pdf_data, dpi=300)
    text = ""
    for page in pages:
        text += pytesseract.image_to_string(page, lang='spa')
    return text


def extract_text_from_pdf(pdf_data: bytes) -> str:
    """Try basic extraction, fall back to OCR if needed."""
    try:
        doc = fitz.open(stream=BytesIO(pdf_data), filetype="pdf")
        text = "".join(page.get_text() for page in doc)
        doc.close()
    except Exception as e:
        logger.exception("Error reading PDF: %s", e)
        text = ""
    if not text.strip():
        logger.info("PDF contains no extractable text, applying OCR")
        text = extract_text_with_ocr(pdf_data)
    return text



def generate_course(file: UploadFile = File(...)):
    """Extract text from an uploaded file and generate a course."""
    _ensure_size_ok(file)
    filename = (file.filename or '').lower()
    content_type = (file.content_type or '').lower()

    # Read the uploaded file contents
    data = file.file.read()
    size = len(data)
    logger.info("Processing file '%s' (%d bytes)", filename, size)

    # Handle plain text files
    if filename.endswith('.txt') and 'text/plain' in content_type:
        try:
            try:
                contents = data.decode('utf-8')
            except UnicodeDecodeError:
                try:
                    contents = data.decode('latin-1')
                except UnicodeDecodeError:
                    contents = data.decode('utf-8', errors='ignore')
        except Exception as e:
            logger.exception("Error decoding text: %s", e)
            raise HTTPException(status_code=422, detail="Error decoding text")

    # Handle PDF files
    elif filename.endswith('.pdf') and 'pdf' in content_type:
        try:
            contents = extract_text_from_pdf(data)
        except Exception as e:
            logger.exception("Error reading PDF: %s", e)
            raise HTTPException(status_code=422, detail="Error reading PDF")
    else:
        raise HTTPException(status_code=400, detail="Only .txt or .pdf files are supported")

    # Ensure the content stays within the model's limits
    token_count = estimate_tokens(contents)
    truncated = False
    if token_count > MAX_MODEL_TOKENS:
        contents = truncate_text_to_tokens(contents, MAX_MODEL_TOKENS)
        truncated = True
        token_count = estimate_tokens(contents)

    # Split the input into manageable chunks for the LLM
    try:
        chunks = split_text_into_chunks(contents, max_tokens=10_000)
    except ValueError as exc:
        logger.error("Unable to split text: %s", exc)
        raise HTTPException(status_code=400, detail="File too large to process")

    partial_summaries = []  # Store each chunk summary
    for chunk in chunks:
        prompt = (
            "Summarize the following part of a course document:\n\n" + chunk
        )
        partial_summaries.append(ask_llm(prompt))

    # Combine partial summaries and ask for a final overall summary
    aggregated = "\n".join(partial_summaries)
    final_prompt = (
        "Combine these summaries into a coherent course outline:\n\n" + aggregated
    )
    final_summary = ask_llm(final_prompt)
    # Include a warning if we had to cut off the input text
    result = {"course": final_summary}
    if truncated:
        result["warning"] = "Input text truncated to fit token limit."
    return result
