# backend/tests/test_flashcards_quality.py

import asyncio
import json
import re
import sys
import types
from pathlib import Path

import pytest

# add project and backend roots to sys.path
ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
BACKEND_ROOT = ROOT / "backend"
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

# provide a minimal dotenv stub so config import succeeds without the package
sys.modules.setdefault("dotenv", types.SimpleNamespace(load_dotenv=lambda *a, **k: None))
# requerir pypdf; si falta, pytest lo marca como "skipped" con mensaje útil
pypdf = pytest.importorskip("pypdf", reason="Install with: pip install pypdf")
from pypdf import PdfReader

TRIVIAL = {
    "with","from","that","which","including","summary","abstract",
    "introduction","intro","overview","conclusion",
    "resumen","introducción","conclusión"
}
HDR = re.compile(r'^\s*\*\*(summary|overview|resumen|introducción)\*\*\s*[:-]?\s*', re.I)

def _norm(s: str) -> str:
    return " ".join((s or "").lower().split())

def _clean_def(s: str) -> str:
    return HDR.sub("", s or "").strip()

def _token_set_ratio(a: str, b: str) -> float:
    A, B = set(_norm(a).split()), set(_norm(b).split())
    if not A or not B: return 0.0
    inter = len(A & B); denom = max(1, min(len(A), len(B)))
    return inter / denom * 100

def validate_flashcards(cards, target=12, dup_threshold=88):
    assert len(cards) == target, f"Expected {target}, got {len(cards)}"
    seen_terms, defs, multi = set(), [], 0
    for c in cards:
        term = _norm(c.get("term",""))
        definition = _clean_def(c.get("definition",""))
        assert term not in TRIVIAL, f"Trivial term leaked: {term}"
        assert term not in seen_terms, f"Repeated term: {term}"
        seen_terms.add(term)
        assert len(definition.split()) >= 15, f"Short def for {term}"
        assert not HDR.match(c.get("definition","") or ""), f"Heading not stripped for {term}"
        for d in defs:
            sim = _token_set_ratio(definition, d)
            assert sim < dup_threshold, f"Near-duplicate defs (~{sim:.1f}) between '{term}' and another card"
        defs.append(definition)
        if len(term.split()) >= 2:
            multi += 1
    assert multi >= 4, f"Too few multi-word terms (got {multi})"

@pytest.fixture(scope="module")
def corto_pdf_text():
    pdf_path = Path(__file__).parent / "corto.pdf"
    assert pdf_path.exists(), f"{pdf_path} not found (put corto.pdf in backend/tests/)"
    reader = PdfReader(str(pdf_path))
    text = ""
    for page in reader.pages:
        text += (page.extract_text() or "") + "\n"
    return text

DEFAULT_TERMS = [
    "mark twain", "tom sawyer", "huckleberry finn", "mississippi river",
    "american literature", "becky", "school", "adventure",
    "friendship", "riverboat", "hannibal", "author"
]


def _parse_target(prompt: str, default=12) -> int:
    m = re.search(r"Create\s+EXACTLY\s+(\d+)", prompt, re.I)
    return int(m.group(1)) if m else default


def _parse_terms(prompt: str) -> list[str]:
    terms: list[str] = []
    block = re.split(r"TERMS TO DEFINE:\s*", prompt, flags=re.I)
    if len(block) > 1:
        for ln in block[1].splitlines():
            ln = ln.strip()
            if ln.startswith("- "):
                t = ln[2:].strip(" •-:\t")
                if t:
                    terms.append(t)
    if not terms:
        terms = re.findall(r'"term"\s*:\s*"([^"]+)"', prompt)
    return [t for t in terms if t]


def _fake_llm_response(prompt: str) -> str:
    """Return a deterministic set of twelve flashcards for offline tests.

    The real implementation normally depends on an LLM.  For test isolation we
    synthesise a response that mimics the production structure:

    * Always produce exactly 12 flashcards.
    * Use any terms provided in the prompt and fall back to ``DEFAULT_TERMS``.
    * Definitions are long (>=15 words) and unique via the card index.
    * The payload is wrapped in ``<json>``/``</json>`` markers.
    """

    target = 12  # fixed output size for offline tests
    terms = _parse_terms(prompt)

    pool: list[str] = []
    seen: set[str] = set()

    def _add(term: str) -> None:
        """Add ``term`` to ``pool`` if it's non-empty and unique."""
        tt = (term or "").strip()
        if not tt:
            return
        key = tt.lower()
        if key in seen:
            return
        seen.add(key)
        pool.append(tt)

    for t in terms:
        if len(pool) >= target:
            break
        _add(t)

    for t in DEFAULT_TERMS:
        if len(pool) >= target:
            break
        _add(t)

    # Ensure the pool has exactly ``target`` entries, inventing extras if
    # necessary (extremely unlikely, but keeps the function robust).
    filler_idx = 1
    while len(pool) < target:
        _add(f"extra term {filler_idx}")
        filler_idx += 1

    cards = []
    for i, term in enumerate(pool, 1):
        definition = (
            f"{term.title()} — offline definition number {i} provides extensive explanation for testing purposes, "
            f"includes clear context and distinct phrasing, and adds many descriptive words to meet the minimum "
            f"length requirement for thorough comprehension descriptor{i} token{i} extra{i}."
        )
        cards.append({"term": term, "definition": definition})

    return "<json>" + json.dumps({"flashcards": cards}) + "</json>"


@pytest.mark.asyncio
async def test_flashcards_quality_with_pdf_offline(monkeypatch, corto_pdf_text):
    from backend.app.utils import llm as llm_mod

    # Never call the real network — monkeypatch ask_llm
    monkeypatch.setattr(llm_mod, "ask_llm", lambda prompt, **kw: _fake_llm_response(prompt))

    # Run generate_items in a worker thread to support sync/awaitable implementations
    try:
        result = await asyncio.to_thread(
            llm_mod.generate_items,
            corto_pdf_text,
            targets={"flashcards": 12, "quiz": 0}
        )
    except TypeError:
        result = await asyncio.to_thread(llm_mod.generate_items, corto_pdf_text)

    # Support both (flashcards, quiz) or {"flashcards": ...}
    if isinstance(result, tuple):
        flashcards = result[0]
    elif isinstance(result, dict):
        flashcards = result.get("flashcards", [])
    else:
        raise AssertionError(f"Unexpected return type from generate_items: {type(result)}")

    validate_flashcards(flashcards, target=12)
