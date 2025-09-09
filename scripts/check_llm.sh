#!/bin/sh
docker compose exec backend sh -lc "apk add --no-cache curl >/dev/null 2>&1 || true; curl -s http://llm:11434/v1/models"
