import os
from pathlib import Path
from dotenv import load_dotenv
import logging
from fastapi import HTTPException
import anthropic
import openai

# Load API key from backend/.env
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(env_path)

anthropic_client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
openai.api_key = os.getenv("OPENAI_API_KEY")

PROVIDER = os.getenv("MODEL_PROVIDER", "claude").lower()
CLAUDE_MODEL = os.getenv("CLAUDE_MODEL", "claude-3-haiku-20240307")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")

logger = logging.getLogger(__name__)

def ask_llm(prompt: str) -> str:
    """Send a prompt to the configured LLM provider."""
    try:
        if PROVIDER == "openai":
            logger.info("Using provider=%s model=%s", PROVIDER, OPENAI_MODEL)
            resp = openai.ChatCompletion.create(
                model=OPENAI_MODEL,
                messages=[{"role": "user", "content": prompt}],
            )
            return resp["choices"][0]["message"]["content"].strip()

        logger.info("Using provider=%s model=%s", PROVIDER, CLAUDE_MODEL)
        resp = anthropic_client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=1024,
            system="You are a helpful assistant.",
            messages=[{"role": "user", "content": prompt}],
        )
        return resp.content[0].text.strip()
    except Exception as exc:
        logger.exception("LLM request failed with %s: %s", PROVIDER, exc)
        raise HTTPException(status_code=500, detail="LLM request failed")
