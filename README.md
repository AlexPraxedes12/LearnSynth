# LearnSynth

Convierte **texto, audio o video** en materiales de estudio estructurados — **resúmenes, mapas de conceptos, tarjetas (flashcards), quizzes y preguntas de reflexión** — con una app **Flutter** y un backend **FastAPI** que orquesta **LLMs open‑source y alojados** (por defecto: **gpt‑oss‑20b**, API compatible con OpenAI).

**Enlaces rápidos**  
[🌐 Website (Flutter Web)](https://learnsynth.com) • [🎬 Demo en video](https://youtu.be/tUp1egYCSEA) • [📦 Último release](https://github.com/AlexPraxedes12/LearnSynth/releases/tag/v0.3.0) • [📱 APK](https://github.com/AlexPraxedes12/LearnSynth/releases/download/v0.3.0/app-release.apk) • [🪟 Windows Setup](https://github.com/AlexPraxedes12/LearnSynth/releases/download/v0.3.0/LearnSynth-Setup-1.0.0.exe)

---

## ¿Qué hace?

- **Ingesta de archivos**: texto / PDF / audio / video. Audio y video pueden transcribirse (Whisper).
- **Generación de “study packs”** en paralelo: resumen, mapa de conceptos, prompts profundos, cloze drills y quizzes.
- **Abstracción de LLMs**: OpenAI‑compatible OSS (**gpt‑oss‑20b** por defecto), OpenAI, Anthropic o Replicate — seleccionable por variables de entorno.
- **Exportación**: Markdown → TXT/PDF. **Texto a voz** (gTTS) opcional.
- **Spaced Repetition**: motor SRS mínimo para tarjetas.

---

## Capturas

<img src="docs/Add.jpg" width="260"> <img src="docs/Library.jpg" width="260"> <img src="docs/Progress.jpg" width="260">

---

## ¿Por qué **gpt‑oss‑20b**?

- **Abierto** y reproducible vía API compatible con OpenAI.  
- Buen desempeño general para **resumir, seleccionar términos clave y generar Q&A**.  
- **Plug‑and‑play** con la capa de proveedores del backend; se puede conmutar por modelos alojados cuando convenga.

---

## Estructura

```
frontend/learns/        # App Flutter (Android / Windows / Web)
backend/                # FastAPI (análisis, ruteo LLM, export, TTS)
learnsynth_offline_llm/ # (opcional) módulo Flutter para GGUF on‑device (feature‑flagged)
docs/                   # Guías e imágenes
scripts/                # Utilidades
```

**Backend (destacado)**  
- `app/utils/llm.py` – ruteo de proveedores (OSS/OpenAI/Anthropic/Replicate), estimación de tokens y troceado.  
- `app/services/generator.py` – transcripción, PDF/OCR, *chunked summarization* y generación de items.  
- `app/services/exporter.py` – Markdown → TXT/PDF.  
- `app/services/srs.py` – mini motor SRS para tarjetas.

---

## Stack

**Frontend**: Flutter/Dart (`provider`, `shared_preferences`, `hive`, `connectivity_plus`, `ffmpeg_kit_flutter_new`, etc.)  
**Backend**: Python 3.11, FastAPI, Uvicorn, `httpx`, `sse-starlette`, `PyMuPDF`, `pdf2image`, `pytesseract`, `tiktoken`, SDKs de OpenAI/Anthropic/Replicate  
**TTS/ASR**: gTTS, Whisper  
**Deploy**: Docker/Compose (listo para Cloud Run/Railway/Render)

---

## Ejecutar local

### 1) Backend

```bash
cd backend
cp .env.example .env   # configura claves SOLO si usarás proveedores alojados
# Ejemplo: LLM_PROVIDER=oss, OSS_MODEL=gpt-oss-20b
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
# → http://localhost:8000
```

> **Seguridad:** mantén las claves fuera de git. `.env` está ignorado. El backend **enmascara** tokens en logs.

### 2) App Flutter

```bash
cd frontend/learns
flutter pub get

# Desarrollo local apuntando a tu backend:
flutter run --dart-define=API_BASE=http://localhost:8000             --dart-define=ENABLE_OFFLINE_LLM=false
```

**Builds (ejemplos)**

```bash
# Web (público / solo online)
flutter build web --release   --dart-define=API_BASE=https://tu-api.example.dev   --dart-define=ENABLE_OFFLINE_LLM=false

# Windows
flutter build windows --release   --dart-define=API_BASE=https://tu-api.example.dev   --dart-define=ENABLE_OFFLINE_LLM=false

# Android (APK)
flutter build apk --release   --dart-define=API_BASE=https://tu-api.example.dev   --dart-define=ENABLE_OFFLINE_LLM=false
```

**Flags (por defecto y seguridad)**

- `API_BASE` – URL del backend. En builds de producción solemos apuntar a una API pública; puedes **sobrescribir** con `--dart-define=API_BASE=...`.  
- `ENABLE_OFFLINE_LLM` – **false** por defecto. Actívalo sólo si instalaste modelos GGUF locales y habilitaste el módulo.

---

## Descargas e instalación

Descarga desde el **[último release](https://github.com/AlexPraxedes12/LearnSynth/releases/tag/v0.3.0)**.

- **Android**: habilita *Install unknown apps* y abre `app-release.apk`.  
- **Windows**: ejecuta `LearnSynth-Setup-*.exe`. Si SmartScreen advierte, **More info → Run anyway**.

**Verificar checksums (opcional)**

```powershell
# Windows PowerShell
Get-FileHash .pp-release.apk -Algorithm SHA256
Get-FileHash .\LearnSynth-Setup-*.exe -Algorithm SHA256
```

---

## Variables de entorno (backend)

Desde `.env.example` (las más comunes):

- `LLM_PROVIDER` (`oss`, `openai`, `anthropic`, `replicate`)  
- `OSS_MODEL` (por defecto `gpt-oss-20b`)  
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `REPLICATE_API_TOKEN` (opcionales; necesarios sólo si usas esos proveedores)  
- **Targets** de generación: `FLASHCARD_TARGET`, `QUIZ_TARGET`, `DEEP_TARGET`, `CLOZE_TARGET`  
- **Límites** de subida: `MAX_MEDIA_BYTES`

---

## Roadmap (corto)

- Pulido de exportación web y enlaces compartibles  
- Layouts más ricos para mapas de conceptos  
- Ruta **full offline** opcional con packs curados de GGUF

---

## Contribuir

¡PRs bienvenidos! Pruebas del backend:

```bash
cd backend
pytest -q
```

---

## Licencia

MIT — ver `LICENSE`. Atribuciones en `THIRD_PARTY_NOTICES.md`.

---

**¡Gracias por probar LearnSynth!** Los jueces podrán ir directo con los enlaces de arriba (Website, Demo, APK, Windows).
