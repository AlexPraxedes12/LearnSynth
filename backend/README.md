# Backend

## Quick Start

```bash
cp .env.example .env
```

### Local Ollama (default)

```bash
docker compose up --build
```

### vLLM

```bash
docker compose --profile vllm up --build
```

## Connectivity Checks

```bash
docker compose exec backend sh -lc "apk add --no-cache curl >/dev/null 2>&1 || true; curl -s http://llm:11434/v1/models"
curl -X POST http://localhost:8000/analyze -H "Content-Type: application/json" -d '{"text":"Short sample"}'
```

### JSON desde Windows PowerShell
`Set-Content -Encoding UTF8` en Windows PowerShell 5 añade BOM y puede romper `application/json`.
Preferir:
- `ConvertTo-Json` + `--data-binary` (sin archivo), o
- escribir el archivo con UTF-8 **sin BOM**. Ejemplo en Python: `scripts/call_backend.py`.
Este backend acepta JSON con BOM gracias a un middleware de normalización.
