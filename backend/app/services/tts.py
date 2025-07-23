import uuid
from pathlib import Path
from gtts import gTTS

TMP_DIR = Path('/tmp')


def text_to_speech(text: str) -> Path:
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    filename = TMP_DIR / f"tts_{uuid.uuid4().hex}.mp3"
    tts = gTTS(text)
    tts.save(str(filename))
    return filename
