from fastapi import UploadFile, File, HTTPException
from io import BytesIO
import fitz  # PyMuPDF

from app.utils.llm import ask_llm


def generate_course(file: UploadFile = File(...)):
    """Extract text from an uploaded file and generate a course."""
    filename = file.filename.lower()

    if filename.endswith('.txt'):
        try:
            contents = file.file.read().decode('utf-8')
        except Exception:
            raise HTTPException(status_code=400, detail="Error decoding .txt file")

    elif filename.endswith('.pdf'):
        try:
            pdf_data = BytesIO(file.file.read())
            doc = fitz.open(stream=pdf_data, filetype="pdf")
            contents = ""
            for page in doc:
                contents += page.get_text()
            doc.close()
        except Exception:
            raise HTTPException(status_code=400, detail="Error reading PDF content")

    else:
        raise HTTPException(status_code=400, detail="Only .txt or .pdf files are supported")

    return {"course": ask_llm(contents)}
