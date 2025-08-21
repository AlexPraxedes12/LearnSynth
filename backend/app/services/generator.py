import os
import logging
from fastapi import UploadFile, File, HTTPException
from io import BytesIO
import fitz  # PyMuPDF
from pdf2image import convert_from_bytes
import pytesseract
import openai

from app.utils.llm import (
    ask_llm,
    split_text_into_chunks,
    truncate_text_to_tokens,
    estimate_tokens,
    MAX_MODEL_TOKENS,
)

logger = logging.getLogger(__name__)
MAX_MEDIA_BYTES = int(os.getenv("MAX_MEDIA_BYTES", str(100 * 1024 * 1024)))  # 100 MB default
logger.info("MAX_MEDIA_BYTES=%s", MAX_MEDIA_BYTES)


def _ensure_size_ok(upload_file):
    # Works with FastAPI UploadFile
    upload_file.file.seek(0, os.SEEK_END)
    size = upload_file.file.tell()
    upload_file.file.seek(0)
    if size > MAX_MEDIA_BYTES:
        logger.info("File too large: %s bytes", size)
        raise HTTPException(status_code=400, detail="File too large")


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


def _transcribe_media(data: bytes, filename: str) -> str:
    """Use Whisper to transcribe audio or video data into text."""
    try:
        file_like = BytesIO(data)
        file_like.name = filename or "upload"
        # Support both old and new OpenAI Python client interfaces
        if hasattr(openai, "Audio") and hasattr(openai.Audio, "transcriptions"):
            response = openai.Audio.transcriptions.create(
                model="whisper-1", file=file_like
            )
        else:  # Fallback for legacy clients
            response = openai.Audio.transcribe("whisper-1", file_like)

        if isinstance(response, dict):
            return response.get("text", "")
        return getattr(response, "text", "")
    except Exception as exc:
        logger.exception("Transcription failed: %s", exc)
        raise HTTPException(status_code=500, detail="Transcription failed")


def transcribe_audio(file: UploadFile = File(...)) -> str:
    """Transcribe an uploaded audio file using Whisper."""
    _ensure_size_ok(file)
    data = file.file.read()
    size = len(data)
    logger.info("Transcribing audio '%s' (%d bytes)", file.filename, size)
    return _transcribe_media(data, file.filename or "audio")


def transcribe_video(file: UploadFile = File(...)) -> str:
    """Transcribe an uploaded video file using Whisper."""
    _ensure_size_ok(file)
    data = file.file.read()
    size = len(data)
    logger.info("Transcribing video '%s' (%d bytes)", file.filename, size)
    return _transcribe_media(data, file.filename or "video")


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
