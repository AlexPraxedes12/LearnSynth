import sys
import requests

BASE_URL = "http://localhost:8000"


def check(path: str, payload: dict | None = None) -> None:
    url = BASE_URL + path
    try:
        resp = requests.post(url, json=payload or {}, timeout=15)
    except Exception as exc:  # pragma: no cover - network failure
        print(f"{path} -> exception: {exc}")
        sys.exit(1)
    print(f"{path} -> {resp.status_code}")
    if resp.status_code != 200:
        print(resp.text[:200])
        sys.exit(1)
    try:
        data = resp.json()
    except Exception:
        print("Invalid JSON", resp.text[:200])
        sys.exit(1)
    for key in ["summary", "deep_prompts", "concept_map", "quiz", "errors"]:
        if key not in data:
            print(f"Missing key: {key}")
            sys.exit(1)


def check_health() -> None:
    url = BASE_URL + "/health"
    resp = requests.get(url, timeout=5)
    print(f"/health -> {resp.status_code}")
    if resp.status_code != 200:
        print(resp.text[:200])
        sys.exit(1)


if __name__ == "__main__":
    check_health()
    check("/analyze", {"text": "hello world"})
    check("/study-mode", {"text": "hello world"})
