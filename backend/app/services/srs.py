import json
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict

DATA_FILE = Path(__file__).parent / "srs_cards.json"

if not DATA_FILE.exists():
    DATA_FILE.write_text("[]")

def _load_cards() -> List[Dict]:
    return json.loads(DATA_FILE.read_text())

def _save_cards(cards: List[Dict]):
    DATA_FILE.write_text(json.dumps(cards, indent=2))


def add_flashcards(cards: List[Dict]) -> List[Dict]:
    existing = _load_cards()
    now = datetime.utcnow()
    new_cards = []
    for card in cards:
        entry = {
            "id": str(uuid.uuid4()),
            "front": card["front"],
            "back": card["back"],
            "interval": 1,
            "next_review": now.isoformat(),
            "difficulty": card.get("difficulty", 0),
        }
        existing.append(entry)
        new_cards.append(entry)
    _save_cards(existing)
    return new_cards


def get_due_flashcards() -> List[Dict]:
    cards = _load_cards()
    now = datetime.utcnow().isoformat()
    return [c for c in cards if c["next_review"] <= now]


def update_flashcard(card_id: str, feedback: str) -> Dict:
    cards = _load_cards()
    now = datetime.utcnow()
    updated = None
    for c in cards:
        if c["id"] == card_id:
            if feedback == "easy":
                c["interval"] = c.get("interval", 1) * 2
            elif feedback == "hard":
                c["interval"] = 1
            next_time = now + timedelta(days=c["interval"])
            c["next_review"] = next_time.isoformat()
            c["difficulty"] = 0 if feedback == "easy" else 1
            updated = c
            break
    if updated:
        _save_cards(cards)
    return updated
