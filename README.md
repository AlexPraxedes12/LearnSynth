# LearnSynth

## Overview

LearnSynth turns raw text, audio or video into a structured study pack.  The
Flutter front‑end lets learners upload material and review generated quizzes,
concept maps and reflective prompts.  The FastAPI backend orchestrates LLMs and
transcription services to build these study aids.

## Architecture

```
Flutter UI → FastAPI backend → LLM provider
                              ↳ OSS (vLLM/Ollama) or SaaS fallback
```

The backend selects the LLM at runtime via environment variables.  When
`LLM_PROVIDER=oss` the server first tries an OpenAI compatible `/v1`
endpoint (vLLM or Ollama) and falls back to the native Ollama API if needed.
`LLM_FALLBACK_PROVIDER` can point to `openai` or `anthropic` for hosted models.

## Quick Start – Local (Docker Compose)

Run the backend and local Ollama service from the `backend` directory:

```bash
cd backend
cp .env.example .env
docker compose up --build
```

Verify connectivity from inside the backend container and hit the API:

```bash
cd backend
docker compose exec backend sh -lc "apk add --no-cache curl >/dev/null 2>&1 || true; curl -s http://llm:11434/v1/models"
curl -X POST http://localhost:8000/analyze -H "Content-Type: application/json" -d '{"text":"Short sample"}'
```

## Quick Start – Cloud

Deploy the backend container to Cloud Run, Railway or Render.  For Cloud Run:

```bash
gcloud run services replace cloudrun.yaml
```

Replace `PROJECT_ID` and `YOUR-LLM-ENDPOINT` in the manifest with your
project and LLM URL.

## Environment variables

These are read by the backend and Docker images:

| Name | Purpose |
| --- | --- |
| `LLM_PROVIDER` | Primary provider (`oss`, `openai`, `anthropic`) |
| `LLM_FALLBACK_PROVIDER` | Secondary provider if the primary fails |
| `LLM_TIMEOUT_SEC` | HTTP timeout for LLM calls |
| `OSS_API_BASE` | Base URL for OpenAI-compatible OSS endpoint |
| `OSS_MODEL` | Model name for the OSS `/v1` endpoint |
| `OLLAMA_BASE` | Base URL for Ollama native API |
| `OLLAMA_MODEL` | Model name for Ollama |
| `OPENAI_API_KEY` | API key for OpenAI fallback |
| `ANTHROPIC_API_KEY` | API key for Anthropic fallback |
| `FLASHCARD_TARGET`, `QUIZ_TARGET`, `DEEP_TARGET`, `CLOZE_TARGET` | Optional item count hints |

No secret values are committed; inject them via your environment or cloud
secret manager.

## Testing

Run the backend locally and hit the analysis endpoint:

```bash
curl -s localhost:8000/analyze -H 'Content-Type: application/json' \
  -d '{"text":"short example"}' | jq
```

The response always contains `summary`, `deep_prompts`, `concept_map`, `quiz`
and `errors` keys.

## Flutter: switching LLM backends

The Flutter app can route text generation either to a local model or to
Replicate. Open the **Ajustes** screen, enter a Replicate API token or a local
model path, and tap **Usar Replicate** or **Usar local** to switch between
backends.

## Security & Privacy

API keys are loaded from environment variables or secret managers at runtime;
they are never checked into the repository.  When using OSS models all
processing can stay on local hardware.

## License & Attribution

This project is released under the MIT License (see `LICENSE`).  Model weights
belong to their respective authors (e.g. Meta for Llama‑3.1).  Spacy and other
third‑party libraries are used under their respective licenses.

