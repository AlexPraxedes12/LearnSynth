from typing import Literal
import markdown
from bs4 import BeautifulSoup
from weasyprint import HTML


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
