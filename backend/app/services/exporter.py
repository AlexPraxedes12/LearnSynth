from typing import Literal
from pathlib import Path
import uuid

import markdown
from bs4 import BeautifulSoup
from weasyprint import HTML

TMP_DIR = Path("/tmp")


def export_content(content: str, fmt: Literal['md', 'txt', 'pdf']):
    if fmt == 'md':
        return content
    html = markdown.markdown(content)
    if fmt == 'txt':
        soup = BeautifulSoup(html, 'html.parser')
        return soup.get_text()
    if fmt == 'pdf':
        return HTML(string=html).write_pdf()
    raise ValueError('Unsupported format')


def export_to_pdf_file(content: str) -> Path:
    """Export Markdown content to a temporary PDF file."""
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    pdf_bytes = export_content(content, 'pdf')
    filename = TMP_DIR / f"export_{uuid.uuid4().hex}.pdf"
    with open(filename, "wb") as f:
        f.write(pdf_bytes)
    return filename
