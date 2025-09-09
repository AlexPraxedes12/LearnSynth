from typing import Literal
from pydantic import BaseModel, Field

class Flashcard(BaseModel):
    """Input model for creating or storing a flashcard."""
    question: str = Field(..., example="What is AI?")
    answer: str = Field(..., example="Artificial Intelligence")
    ease_factor: float = Field(..., example=2.5)

class ConceptMapInput(BaseModel):
    """Text input for concept map generation."""
    text: str = Field(..., example="Introduction to machine learning")

# New request model for the concept map image endpoint
class ConceptMapRequest(BaseModel):
    """Request body for generating a concept map image."""
    text: str

class ReviewInput(BaseModel):
    """Feedback provided when reviewing a flashcard."""
    feedback: str = Field(..., example="easy")

class ExportInput(BaseModel):
    """Parameters for exporting generated content."""
    content: str = Field(..., example="# Title\nSome markdown content")
    fmt: Literal['md', 'txt', 'pdf'] = Field(..., example="pdf")

class TTSInput(BaseModel):
    """Text to convert into speech."""
    text: str = Field(..., example="Hola mundo")
