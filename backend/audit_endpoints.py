import requests
import json

BASE_URL = "http://localhost:8000"

# Endpoints y payloads de prueba corregidos
endpoints = [
    {
        "method": "POST",
        "path": "/generate",
        "files": {"file": ("test.txt", b"Texto de ejemplo para prueba", "text/plain")},
    },
    {
        "method": "POST",
        "path": "/flashcards",
        "json": [
            {"question": "¿Qué es IA?", "answer": "Inteligencia Artificial", "ease_factor": 2.5}
        ],
    },
    {
        "method": "GET",
        "path": "/flashcards/due",
    },
    {
        "method": "POST",
        "path": "/flashcards/1/review",
        "json": {"feedback": "Buena tarjeta"},
    },
    {
        "method": "POST",
        "path": "/concept-map",
        "json": {"text": "La inteligencia artificial incluye aprendizaje automático y redes neuronales."},
    },
    {
        "method": "POST",
        "path": "/concept-map/image",
        "json": {"text": "Mapa conceptual sobre inteligencia artificial"},
    },
    {
        "method": "POST",
        "path": "/export",
        "json": {
            "content": "Este es un texto de prueba para exportar.",
            "fmt": "pdf"
        },
    },
    {
        "method": "POST",
        "path": "/tts",
        "json": {"text": "Hola, esta es una prueba de texto a voz."},
    },
]

# Ejecutar auditoría
for ep in endpoints:
    url = BASE_URL + ep["path"]
    print(f"\n>>> Probing {ep['method']} {url}")

    try:
        if ep["method"] == "POST":
            if "files" in ep:
                response = requests.post(url, files=ep["files"])
            else:
                response = requests.post(url, json=ep.get("json", {}))
        elif ep["method"] == "GET":
            response = requests.get(url)

        print(f"Status: {response.status_code}")
        if response.status_code != 200:
            print("❌ ERROR:", response.text[:300])
        else:
            print("✅ Success")
    except Exception as e:
        print("❌ Exception occurred:", str(e))
