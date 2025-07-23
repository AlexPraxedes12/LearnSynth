from fastapi import FastAPI, UploadFile, File
from app.services.generator import generate_course

app = FastAPI()

@app.post('/generate')
async def generate(file: UploadFile = File(...)):
    contents = await file.read()
    return generate_course(contents)
