from fastapi import FastAPI, UploadFile, File, Body, HTTPException, BackgroundTask
from fastapi.responses import FileResponse, Response
import os
import logging
from typing import List

from app.services.generator import generate_course
from app.services import srs, concept_map, exporter, tts
from app.models import (
    Flashcard,
    ConceptMapInput,
    ConceptMapRequest,
    ReviewInput,
    ExportInput,
    TTSInput,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()


@app.post('/generate', tags=["Generation"])
async def generate(file: UploadFile = File(...)):
    """Generate a course outline from an uploaded PDF or text file."""
    try:
        return generate_course(file)
    except HTTPException as exc:
        raise exc
    except Exception as exc:
        logger.exception("Unexpected error generating course: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/flashcards', tags=["Flashcards"])
def save_flashcards(
    cards: List[Flashcard] = Body(
        ...,
        example=[
            {
                "question": "What is AI?",
                "answer": "Artificial Intelligence",
                "ease_factor": 2.5,
            }
        ],
    )
):
    """Persist a list of flashcards for spaced repetition."""
    try:
        payload = [
            {"front": c.question, "back": c.answer, "difficulty": c.ease_factor}
            for c in cards
        ]
        return srs.add_flashcards(payload)
    except Exception as exc:
        logger.exception("Failed to save flashcards: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.get('/flashcards/due', tags=["Flashcards"])
def due_flashcards():
    """Return flashcards that are due for review."""
    try:
        return srs.get_due_flashcards()
    except Exception as exc:
        logger.exception("Failed to load due flashcards: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/flashcards/{card_id}/review', tags=["Flashcards"])
def review_flashcard(card_id: str, review: ReviewInput = Body(...)):
    """Record review feedback for a given flashcard."""
    try:
        return srs.update_flashcard(card_id, review.feedback)
    except Exception as exc:
        logger.exception("Failed to review flashcard %s: %s", card_id, exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/concept-map', tags=["Concept Map"])
def create_concept_map(data: ConceptMapInput = Body(...)):
    """Generate a concept map from the provided text."""
    try:
        return concept_map.generate_concept_map(data.text)
    except Exception as exc:
        logger.exception("Failed to create concept map: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/concept-map/image', tags=["Concept Map"])
def concept_map_img(data: ConceptMapRequest = Body(...)):
    """Generate a concept map from text and return a PNG image."""
    try:
        cmap = concept_map.generate_concept_map(data.text)
        img = concept_map.concept_map_image(cmap)
        return Response(content=img, media_type='image/png')
    except Exception as exc:
        logger.exception("Failed to create concept map image: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/export', tags=["Export"])
def export_course(data: ExportInput = Body(...)):
    """Export Markdown content to `md`, `txt` or `pdf` format."""
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


@app.post('/tts', tags=["Text-to-Speech"])
def text_to_speech(data: TTSInput = Body(...)):
    """Convert text into an MP3 audio file."""
    try:
        path = tts.text_to_speech(data.text)
        return FileResponse(
            path,
            media_type='audio/mpeg',
            background=BackgroundTask(os.remove, path),
        )
    except Exception as exc:
        logger.exception("Text-to-speech failed: %s", exc)
        raise HTTPException(status_code=500, detail="Internal server error")
