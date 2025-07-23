from fastapi import FastAPI, UploadFile, File, Body
from fastapi.responses import FileResponse
from app.services.generator import generate_course
from app.services import srs, concept_map, exporter, tts

app = FastAPI()


@app.post('/generate')
async def generate(file: UploadFile = File(...)):
    contents = await file.read()
    return generate_course(contents)


@app.post('/flashcards')
def save_flashcards(cards: list = Body(...)):
    return srs.add_flashcards(cards)


@app.get('/flashcards/due')
def due_flashcards():
    return srs.get_due_flashcards()


@app.post('/flashcards/{card_id}/review')
def review_flashcard(card_id: str, feedback: str = Body(..., embed=True)):
    return srs.update_flashcard(card_id, feedback)


@app.post('/concept-map')
def create_concept_map(text: str = Body(..., embed=True)):
    return concept_map.generate_concept_map(text)


@app.post('/concept-map/image')
def concept_map_img(text: str = Body(..., embed=True)):
    cmap = concept_map.generate_concept_map(text)
    img = concept_map.concept_map_image(cmap)
    file_path = '/tmp/concept_map.png'
    with open(file_path, 'wb') as f:
        f.write(img)
    return FileResponse(file_path, media_type='image/png')


@app.post('/export')
def export_course(content: str = Body(..., embed=True), fmt: str = Body(...)):
    result = exporter.export_content(content, fmt)
    if fmt == 'pdf':
        file_path = '/tmp/export.pdf'
        with open(file_path, 'wb') as f:
            f.write(result)
        return FileResponse(file_path, media_type='application/pdf')
    return {'content': result}


@app.post('/tts')
def text_to_speech(text: str = Body(..., embed=True)):
    path = tts.text_to_speech(text)
    return FileResponse(path, media_type='audio/mpeg')
