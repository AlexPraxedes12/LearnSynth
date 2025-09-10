# LearnSynth

![Hero placeholder](docs/hero.png)

> **Transforms text, PDFs, audio or video into offline-ready study packs** (summaries, concept maps, quizzes, reflective prompts). Cross‑platform **Flutter** app (Android · Web · Windows) with a **FastAPI** backend orchestrating **open‑source LLMs**.

<p align="left">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-informational">
  <img alt="FastAPI" src="https://img.shields.io/badge/FastAPI-0.11x-informational">
  <img alt="Platforms" src="https://img.shields.io/badge/Platforms-Android%20|%20Web%20|%20Windows-brightgreen">
  <img alt="LLM" src="https://img.shields.io/badge/Open%20Source%20LLM-gpt--oss--20b-blueviolet">
  <img alt="Offline" src="https://img.shields.io/badge/Offline-ready%20(flagged)-blue">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-lightgrey">
</p>

---

## TL;DR for judges
- **Real use case**: turn any content (text/PDF/audio/video) into a structured study pack you can **use offline**.
- **Works today on** Android · Web · Windows. iOS/macOS templates exist in the repo, not shipped in this submission.
- **OSS-first**: uses an **OpenAI‑compatible** endpoint with **gpt‑oss‑20b** by default. Offline LLM code is **gated** and **disabled by default**.

**Demo video (≤ 3 min):** _(add YouTube link)_  
**Live demo:** _(add web URL if available)_  
**Releases:** _(APK / Windows exe links)_

---

## Why it matters
Students and lifelong learners waste time extracting key ideas from long PDFs, lectures or videos. LearnSynth automates that into clear, actionable materials that continue to work **without internet**, making learning more accessible.

---

## What it does
- **Ingests** text, PDFs, audio or video (`/upload-content`).
- **Transcribes** audio/video (Whisper cloud) or uses **Vosk** (offline) when configured.
- **Parses** PDFs (PyMuPDF) and **OCR** fallback (Tesseract) when needed.
- **Generates** study packs via an OSS LLM (OpenAI‑compatible API, default: **gpt‑oss‑20b**):
  - summary → TL;DR
  - concept map → nodes + relations
  - deep understanding prompts → reflection questions
  - quizzes, cloze drills, flashcards (with a minimal SRS engine)
- **Exports** to Markdown/TXT/PDF and **TTS** (MP3) for accessibility.
- **Stores** locally so you can keep studying offline.

---

## Architecture (high‑level)
```
[Flutter UI]
   |  Android · Web · Windows
   v
[FastAPI backend]
   |  Upload: text/PDF/audio/video
   |  ├─ Audio/Video → Transcribe (Whisper or Vosk)
   |  ├─ PDF → PyMuPDF (+ OCR via Tesseract)
   |  └─ Text → normalize
   v
[LLM layer (OpenAI‑compatible)]  →  gpt-oss-20b (default) / Replicate / vLLM / Ollama
   v
[Generators]  →  summary · concept map · prompts · quizzes · cloze · flashcards
   v
[Export & Storage]  →  Markdown/TXT/PDF · TTS MP3 · local/offline access
```

---

## Quick start

### 1) Backend
```bash
cd backend
cp .env.example .env   # fill with your values (no secrets in the repo)
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```
Typical variables (see `backend/.env.example`):
- `OSS_API_BASE`, `OSS_MODEL`  # OpenAI‑compatible endpoint/model (e.g., gpt‑oss‑20b)
- `LLM_PROVIDER=oss`           # default provider
- `OPENAI_API_KEY` / `REPLICATE_API_TOKEN` *(optional, if used)*
- `MAX_MEDIA_BYTES=100_000_000`

> Alternatively: `docker compose up --build` inside `backend/`.

### 2) Frontend (Flutter)
App lives in `frontend/learns/`. The offline LLM module exists but is **feature‑flagged** and **OFF by default**.

**Builds (defaults ok):**
```bash
# Web (production)
flutter build web --release

# Windows (production)
flutter build windows --release

# Android (APK production)
flutter build apk --release
```
`API_BASE` can be hardcoded in code (default) or overridden with `--dart-define=API_BASE=...`.

**Enable offline for local testing (optional):**
```bash
flutter run --dart-define=ENABLE_OFFLINE_LLM=true
```
> Web builds do not use platform‑specific offline plugins; keep the flag off for Web.

---

## One‑minute review path (for judges)
1. Open the app (Web or Windows/Android build).  
2. Click **Add content** and paste a short paragraph *or* upload a small PDF.  
3. Tap **Analyze** → Watch summary, concept map and quizzes appear.  
4. Open **Study methods** and interact with **Memorization / Deep Understanding / Quiz**.  
5. Optionally **Export** (Markdown/PDF) or **Speak** (MP3) for accessibility.  

> You can test fully offline with previously generated packs.

---

## Notes on models & providers
- Default LLM: **gpt‑oss‑20b** via an **OpenAI‑compatible** endpoint (e.g., Replicate/vLLM/Ollama).
- The LLM layer is swappable by env vars; see `backend/.env.example`.
- Offline LLM path exists in `learnsynth_offline_llm/`, **disabled by default** for this submission.

---

## Privacy, safety & licensing
- No secrets in the repository. `.env.example` uses placeholders; `.env` is git‑ignored.
- Local storage for offline study packs; no personal data required.
- License: **MIT** (see `LICENSE` and `THIRD_PARTY_NOTICES.md`).

---

## Limitations & next steps
- Heavier PDFs and long videos take more time to parse/transcribe.
- Concept map layout uses simple heuristics; next step: better graph layout and editing.
- Add more languages and richer TTS voices.
- Optional iOS/macOS shipping.

---

## Submission checklist
- [ ] Public repo URL added to Devpost
- [ ] ≤ 3‑minute **demo video** (YouTube) linked
- [ ] Clear **how‑to‑run** (this README)
- [ ] Mentions **gpt‑oss‑20b** / OSS usage
- [ ] No API keys or certificates in history
- [ ] Optional: APK/EXE/Web links in Releases

---

## Devpost copy (short description)
> LearnSynth converts text, PDFs, audio or video into offline‑ready study packs—summaries, concept maps, quizzes and reflection prompts. It runs on Android, Web and Windows, powered by an open‑source LLM (gpt‑oss‑20b) via an OpenAI‑compatible API. The offline model path exists behind a feature flag and is off by default for this submission.

```
Screenshots
- docs/hero.png          # main UI
- docs/pack_summary.png  # study pack summary
- docs/concept_map.png   # concept map view
- docs/methods.png       # study methods grid
```
