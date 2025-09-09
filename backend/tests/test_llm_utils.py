import types
import sys
import os
import json
from pathlib import Path

# Stub external dependencies before importing the module under test
dotenv_stub = types.ModuleType("dotenv")
dotenv_stub.load_dotenv = lambda *a, **k: None
sys.modules["dotenv"] = dotenv_stub

anthropic_stub = types.SimpleNamespace(Anthropic=lambda *a, **k: None)
sys.modules.setdefault("anthropic", anthropic_stub)

openai_stub = types.ModuleType("openai")
openai_stub.OpenAI = lambda *a, **k: None
sys.modules.setdefault("openai", openai_stub)

# Remove any previously stubbed version of the module and import the real one
sys.modules.pop("app.utils.llm", None)
sys.modules.pop("app.utils", None)
sys.modules.pop("app", None)
# Ensure backend root is on sys.path
sys.path.append(str(Path(__file__).resolve().parents[1]))
import app.utils.llm as llm_module
from app.utils.llm import (
    compute_targets,
    _dedup_flashcards,
    _dedup_quiz,
    chunk_text,
    validate_quiz_item,
    _extract_json_obj,
)


def test_compute_targets_respects_env(monkeypatch):
    monkeypatch.setenv("FLASHCARD_TARGET", "5")
    monkeypatch.setenv("QUIZ_TARGET", "7")
    monkeypatch.setenv("DEEP_TARGET", "2")
    monkeypatch.setenv("CLOZE_TARGET", "4")

    targets = compute_targets("dummy text")
    assert targets == {
        "flashcards": 5,
        "quiz": 7,
        "deep_prompts": 2,
        "cloze": 4,
    }


def test_dedup_flashcards_removes_duplicate_definitions():
    llm_module._deduplicator.clear()
    items = [
        {
            "term": "alpha",
            "definition": "d1 word word word word word word word word word word word word word word word word",
        },
        {
            "term": "beta",
            "definition": "d1 word word word word word word word word word word word word word word word word",
        },
        {
            "term": "alpha",
            "definition": "d1 word word word word word word word word word word word word word word word word",
        },
    ]
    result = _dedup_flashcards(items)
    assert result == [
        {
            "term": "alpha",
            "definition": "d1 word word word word word word word word word word word word word word word word",
        }
    ]


def test_dedup_flashcards_removes_similar_definitions():
    llm_module._deduplicator.clear()
    items = [
        {
            "term": "alpha",
            "definition": "A domesticated animal that lives in houses and enjoys human company every single day in many different contexts",
        },
        {
            "term": "beta",
            "definition": "A domesticated animal that lives in houses and enjoys human company every single day in many different contexts.",
        },
    ]
    result = _dedup_flashcards(items)
    assert result == [
        {
            "term": "alpha",
            "definition": "A domesticated animal that lives in houses and enjoys human company every single day in many different contexts",
        }
    ]


def test_validate_quiz_item():
    item = {"question": "Q", "options": ["A", "B", "C"], "answerIndex": 1}
    assert validate_quiz_item(item) == item

    dup_opts = {"question": "Q", "options": ["A", "A"], "answerIndex": 0}
    assert validate_quiz_item(dup_opts) is None

    bad_answer = {"question": "Q", "options": ["A", "B"], "answer": "C"}
    assert validate_quiz_item(bad_answer) is None


def test_dedup_quiz_uses_validation():
    items = [
        {"question": "Q1", "options": ["A", "B"], "answerIndex": 1},
        {"question": "Q2", "options": ["A", "A"], "answerIndex": 0},
    ]
    assert _dedup_quiz(items) == [
        {"question": "Q1", "options": ["A", "B"], "answerIndex": 1}
    ]


def test_generate_items_global_dedup(monkeypatch):
    llm_module._deduplicator.clear()

    def fake_compute_targets(text):
        return {"flashcards": 1, "quiz": 0, "deep_prompts": 0, "cloze": 0}

    def fake_chunk_text(text, size=200, overlap=40):
        return ["A appears here", "Still about A"]

    def fake_extract_terms(text, target_count=12):
        return ["Alpha"]

    def fake_ask(prompt, **kwargs):
        return json.dumps(
            {
                "flashcards": [
                    {
                        "term": "Alpha",
                        "definition": "A cat is a small domesticated mammal that has lived with humans for thousands of years and often purrs happily.",
                    }
                ]
            }
        )

    monkeypatch.setattr(llm_module, "compute_targets", fake_compute_targets)
    monkeypatch.setattr(llm_module, "chunk_text", fake_chunk_text)
    monkeypatch.setattr(llm_module, "extract_terms_from_text", fake_extract_terms)
    monkeypatch.setattr(llm_module, "ask_llm", fake_ask)

    items = llm_module.generate_items("text")
    assert items["flashcards"] == [
        {
            "term": "Alpha",
            "definition": "A cat is a small domesticated mammal that has lived with humans for thousands of years and often purrs happily.",
        }
    ]


def test_generate_items_processes_duplicate_chunks(monkeypatch):
    llm_module._deduplicator.clear()

    def fake_compute_targets(text):
        return {"flashcards": 1, "quiz": 1, "deep_prompts": 0, "cloze": 0}

    def fake_chunk_text(text, size=200, overlap=40):
        return ["Cats are mammals.", "Cats are mammals."]

    def fake_extract_terms(text, target_count=12):
        return ["Cat"]

    call_count = {"n": 0}

    def fake_ask(prompt, **kwargs):
        call_count["n"] += 1
        return json.dumps(
            {
                "flashcards": [
                    {
                        "term": "Cat",
                        "definition": "A mammal that has been domesticated for thousands of years and often lives alongside humans as a beloved pet.",
                    }
                ],
                "quiz": [
                    {
                        "question": "What is a cat?",
                        "options": [
                            "A mammal that lives with humans",
                            "A plant",
                            "A mineral",
                            "A machine",
                        ],
                        "answerIndex": 0,
                    }
                ],
            }
        )

    monkeypatch.setattr(llm_module, "compute_targets", fake_compute_targets)
    monkeypatch.setattr(llm_module, "chunk_text", fake_chunk_text)
    monkeypatch.setattr(llm_module, "extract_terms_from_text", fake_extract_terms)
    monkeypatch.setattr(llm_module, "ask_llm", fake_ask)

    items = llm_module.generate_items("text")

    assert call_count["n"] >= 2
    assert items["flashcards"] == [
        {
            "term": "Cat",
            "definition": "A mammal that has been domesticated for thousands of years and often lives alongside humans as a beloved pet.",
        }
    ]
    assert items["quiz"] == [
        {
            "question": "What is a cat?",
            "options": [
                "A mammal that lives with humans",
                "A plant",
                "A mineral",
                "A machine",
            ],
            "answerIndex": 0,
        }
    ]


def test_generate_items_handles_deep_and_cloze(monkeypatch):
    llm_module._deduplicator.clear()

    def fake_compute_targets(text):
        return {"flashcards": 0, "quiz": 0, "deep_prompts": 2, "cloze": 2}

    def fake_chunk_text(text, size=200, overlap=40):
        return ["chunk1", "chunk2"]

    def fake_ask(prompt, **kwargs):
        if "reflective prompts" in prompt:
            if "chunk1" in prompt:
                return json.dumps({"deep_prompts": [{"prompt": "p1", "hint": "h1"}]})
            return json.dumps({"deep_prompts": [{"prompt": "p2", "hint": "h2"}]})
        if "fill-in-the-blank" in prompt:
            if "chunk1" in prompt:
                return json.dumps(
                    {"cloze": [{"sentence": "s1 ___", "options": ["o1", "o2"], "answerIndex": 0}]}
                )
            return json.dumps(
                {"cloze": [{"sentence": "s2 ___", "options": ["o1", "o2"], "answerIndex": 0}]}
            )
        return "{}"

    monkeypatch.setattr(llm_module, "compute_targets", fake_compute_targets)
    monkeypatch.setattr(llm_module, "chunk_text", fake_chunk_text)
    monkeypatch.setattr(llm_module, "ask_llm", fake_ask)

    items = llm_module.generate_items("text")

    assert items["deep_prompts"] == [
        {"prompt": "p1", "hint": "h1"},
        {"prompt": "p2", "hint": "h2"},
    ]
    assert items["cloze"] == [
        {"sentence": "s1 ___", "options": ["o1", "o2"], "answerIndex": 0},
        {"sentence": "s2 ___", "options": ["o1", "o2"], "answerIndex": 0},
    ]

def test_chunk_text_sentence_chunks():
    text = "One two three. Four five six. Seven eight nine."
    chunks = chunk_text(text, size=3)
    assert chunks == [
        "One two three.",
        "Four five six.",
        "Seven eight nine.",
    ]


def test_chunk_text_deduplicates_chunks():
    text = "Repeat me. Repeat me. Something new."
    chunks = chunk_text(text, size=2, dedup_threshold=0.8)
    assert chunks == ["Repeat me.", "Something new."]


def test_extract_json_obj_variants():
    assert _extract_json_obj("{\"a\":1}") == {"a": 1}
    assert _extract_json_obj("<json>{\"a\":1}</json>") == {"a": 1}
    assert _extract_json_obj("noise {\"a\":1} tail") == {"a": 1}
    assert _extract_json_obj("{\"a\":{\"b\":1}}") == {"a": {"b": 1}}


def test_extract_terms_prefers_multiword():
    text = (
        "Machine learning enables computers to learn. "
        "Machine learning algorithms are powerful. "
        "Machine is a word. Learning is another."
    )
    terms = llm_module.extract_terms_from_text(text, target_count=3)
    assert any("machine learning" in t for t in terms)
    assert "machine" not in terms
    assert "learning" not in terms


def test_flashcard_acceptance_filters():
    items = [
        {
            "term": "summary",
            "definition": "This long definition should be ignored because the term is blocklisted and therefore unacceptable for study despite having many words in it.",
        },
        {
            "term": "and",
            "definition": "This definition is long enough but the term is a stopword and must be excluded from the resulting flashcards regardless of length.",
        },
        {
            "term": "Alpha",
            "definition": "Alpha is a meaningful concept described with more than fifteen words that provide sufficient context and detail for study.",
        },
        {
            "term": "Beta",
            "definition": "Beta refers to a separate idea explained in over fifteen distinct words offering unique context and clarity for learners who explore it.",
        },
        {
            "term": "Gamma",
            "definition": "Beta refers to a separate idea explained in over fifteen distinct words offering unique context and clarity for learners who explore it.",
        },
        {"term": "Delta", "definition": "Too short."},
    ]
    result = llm_module._dedup_flashcards(items)
    assert result == [
        {
            "term": "Alpha",
            "definition": "Alpha is a meaningful concept described with more than fifteen words that provide sufficient context and detail for study.",
        },
        {
            "term": "Beta",
            "definition": "Beta refers to a separate idea explained in over fifteen distinct words offering unique context and clarity for learners who explore it.",
        },
    ]


def test_no_cross_run_leakage(monkeypatch):
    llm_module._deduplicator.clear()
    llm_module._SEEN_FLASHCARD_TERMS.clear()

    def fake_compute_targets(text):
        return {"flashcards": 1, "quiz": 0, "deep_prompts": 0, "cloze": 0}

    def fake_chunk_text(text, size=200, overlap=40):
        return [text]

    def fake_extract_terms(text, target_count=12):
        return ["Alpha"]

    def parse_terms(prompt: str) -> list[str]:
        if "TERMS:" not in prompt:
            return []
        section = prompt.split("TERMS:", 1)[1].split("TEXT:")[0]
        return [
            line.strip()[2:].strip()
            for line in section.strip().splitlines()
            if line.strip().startswith("-")
        ]

    def fake_ask(prompt, **kwargs):
        terms = parse_terms(prompt)
        if not terms:
            return "{}"
        return json.dumps(
            {
                "flashcards": [
                    {
                        "term": terms[0],
                        "definition": "Long definition for Alpha that easily exceeds twenty words and remains unique and informative for learners everywhere in the world."
                    }
                ]
            }
        )

    monkeypatch.setattr(llm_module, "compute_targets", fake_compute_targets)
    monkeypatch.setattr(llm_module, "chunk_text", fake_chunk_text)
    monkeypatch.setattr(llm_module, "extract_terms_from_text", fake_extract_terms)
    monkeypatch.setattr(llm_module, "ask_llm", fake_ask)

    first = llm_module.generate_flashcards("Alpha text one")
    second = llm_module.generate_flashcards("Alpha text two")
    assert len(first) == 1
    assert len(second) == 1
