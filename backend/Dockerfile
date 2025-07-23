FROM python:3.11-slim

# Install system dependencies for WeasyPrint and other libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpangocairo-1.0-0 \
    libcairo2 \
    libpango-1.0-0 \
    libgdk-pixbuf2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Tools for OCR and PDF conversion
RUN apt-get update && apt-get install -y poppler-utils tesseract-ocr

# Set workdir
WORKDIR /app

# Copy backend source
COPY . .

# Install python dependencies
RUN pip install --no-cache-dir fastapi uvicorn[standard] anthropic python-dotenv gtts \
    spacy beautifulsoup4 weasyprint markdown graphviz

    
RUN pip install --upgrade pip && pip install -r requirements.txt

# Download spaCy model
RUN python -m spacy download en_core_web_sm

# Expose API port
EXPOSE 8000

# Start the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
