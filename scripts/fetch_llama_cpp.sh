#!/usr/bin/env bash
set -euo pipefail
REPO_URL="${1:-https://github.com/ggerganov/llama.cpp.git}"
BRANCH_OR_TAG="${2:-master}"
DEST="$(cd "$(dirname "$0")"/.. && pwd)/learnsynth_offline_llm/android/src/main/cpp/third_party/llama.cpp"

rm -rf "$DEST"
git clone --depth 1 --branch "$BRANCH_OR_TAG" "$REPO_URL" "$DEST"

[ -d "$DEST/src" ] || { echo "Missing $DEST/src"; exit 1; }
[ -d "$DEST/ggml/src" ] || { echo "Missing $DEST/ggml/src"; exit 1; }
echo "llama.cpp fetched OK at $DEST"
