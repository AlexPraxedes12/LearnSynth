#!/usr/bin/env sh
set -e
echo "Checking Ollama (OpenAI-compatible API) ..."
curl -s http://localhost:11434/v1/models | jq .
echo "Chat completion test ..."
curl -s -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"${OSS_MODEL:-gpt-oss-20b}\",\"messages\":[{\"role\":\"user\",\"content\":\"Say ready\"}]}" | jq .
echo "Backend /analyze test ..."
curl -s -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"A short paragraph about the digestive system.\"}" | jq .
