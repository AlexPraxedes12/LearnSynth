# LearnSynth

> **Turn any text / PDF / audio / video into an offline-ready study pack** — summaries, concept maps, quizzes and reflective prompts.  
Cross-platform **Flutter** app (Android · Web · Windows) with a **FastAPI** backend orchestrating open-source LLMs + transcription/OCR.

---

## TL;DR (for judges)
- **Real use case:** convert long content into actionable study material you can keep **offline**.
- **Works today:** Android · Web · Windows. (iOS/macOS templates exist, not part of this submission.)
- **OSS-first:** default model is **gpt-oss-20b** via an **OpenAI-compatible** endpoint. **Offline LLM** code exists but is **feature-flagged and OFF by default**.

**Website:** https://learnsynth.com

[⬇️ Download](https://github.com/AlexPraxedes12/LearnSynth/releases/tag/v0.3.0)
[📱 APK](https://github.com/AlexPraxedes12/LearnSynth/releases/tag/v0.3.0)
[🎬 Demo video](https://youtu.be/tUp1egYCSEA)
[🌐 Web app](https://learnsynth.com)

---

## Screenshots
<p>
  <img src="docs/Add.jpg" alt="Add content screen" width="30%"/>
  <img src="docs/Library.jpg" alt="Library screen" width="30%"/>
  <img src="docs/Progress.jpg" alt="Progress screen" width="30%"/>
</p>

---

## What it does
- **Ingest** text, PDFs, audio or video.
- **Transcribe** audio/video (OpenAI Whisper) and **extract/OCR** PDFs (PyMuPDF + Tesseract).
- **Generate** study packs with an **OpenAI-compatible** LLM (default **gpt-oss-20b**):
  - Summary (TL;DR)
  - Concept map (nodes + relations)
  - Deep-understanding prompts
  - Quizzes, cloze drills and flashcards (simple SRS)
- **Export** to Markdown/TXT/PDF and optional **TTS (MP3)**.
- **Store** locally for continued study **without internet**.

---

## Architecture
```
Flutter UI ──► FastAPI backend
                 ├─ Transcription (Whisper)
                 ├─ PDF + OCR (PyMuPDF + Tesseract)
                 └─ LLM layer (OpenAI-compatible) → gpt-oss-20b / Replicate / vLLM / Ollama
                                 └─ Generators → summary · concept map · prompts · quizzes · cloze · flashcards
```
The LLM provider is selected at runtime via environment variables, with optional fallbacks.

---

## Quick start

### Backend (local)
```bash
cd backend
cp .env.example .env   # fill in values; never commit real secrets
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
Or with Docker:
```bash
cd backend
docker compose up --build
```

### Frontend (Flutter)
```bash
cd frontend/learns

# Web
flutter build web --release

# Windows
flutter build windows --release

# Android
flutter build apk --release
```

**Configuration & security**
- **API_BASE**: production builds default to your hosted API (e.g., `https://learnsynth-api.fly.dev`).  
  To override:
  ```bash
  flutter build <target> --release --dart-define=API_BASE=https://your-backend
  ```
- **ENABLE_OFFLINE_LLM**: feature-flagged and **false by default**.  
  Only for local testing:
  ```bash
  flutter run --dart-define=ENABLE_OFFLINE_LLM=true
  ```
- **Secrets**: `.env` is git-ignored; `.env.example` uses placeholders. Logs never print raw tokens — only presence.

---

## Tech stack
**Frontend (Flutter/Dart)** — provider, shared_preferences, hive, file_picker. Targets: Android · Web · Windows.  
**Backend (Python/FastAPI)** — uvicorn, httpx, sse-starlette. PDF: PyMuPDF + pdf2image + Tesseract (OCR). STT: Whisper (OpenAI).  
**LLM** — OpenAI-compatible endpoint (default **gpt-oss-20b**), optional OpenAI / Anthropic / Replicate or local vLLM/Ollama.  
**Infra** — Docker / Docker Compose; deployable to Cloud Run / Railway / Render.  
**Storage** — client-side (no server DB).

---

## One-minute review path
1. Open the app (Web/Windows/Android).
2. **Add content** → paste a short paragraph or upload a small PDF.
3. Tap **Analyze** and watch summary, concept map and a quiz appear.
4. Try **Study methods** (Memorization / Deep Understanding / Quiz).
5. **Export** as Markdown/PDF or **Speak** to MP3.

---

## License
MIT (see `LICENSE`). Third-party models/libraries are under their own licenses.


This project is released under the MIT License (see `LICENSE`).  Model weights
belong to their respective authors (e.g. Meta for Llama‑3.1).  Spacy and other
third‑party libraries are used under their respective licenses.

