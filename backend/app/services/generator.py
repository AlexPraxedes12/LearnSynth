from fastapi import UploadFile, File, HTTPException
from io import BytesIO
import fitz  # PyMuPDF
import logging

from app.utils.llm import ask_llm

logger = logging.getLogger(__name__)

MAX_SIZE = 5 * 1024 * 1024  # 5MB limit


def generate_course(file: UploadFile = File(...)):
    """Extract text from an uploaded file and generate a course."""
    filename = (file.filename or '').lower()
    content_type = (file.content_type or '').lower()

    data = file.file.read()
    size = len(data)
    logger.info("Processing file '%s' (%d bytes)", filename, size)

    if size > MAX_SIZE:
        logger.error("File too large: %d bytes", size)
        raise HTTPException(status_code=400, detail="File too large")

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

    elif filename.endswith('.pdf') and 'pdf' in content_type:
        try:
            pdf_data = BytesIO(data)
            doc = fitz.open(stream=pdf_data, filetype="pdf")
            contents = "".join(page.get_text() for page in doc)
            doc.close()
        except Exception as e:
            logger.exception("Error reading PDF: %s", e)
            raise HTTPException(status_code=422, detail="Error reading PDF")
    else:
        raise HTTPException(status_code=400, detail="Only .txt or .pdf files are supported")

    prompt = f"Generate a concise course outline from the following content:\n\n{contents}"
    summary = ask_llm(prompt)
    return {"course": summary}
