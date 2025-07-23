import os
from pathlib import Path
from dotenv import load_dotenv
import anthropic

# Load API key from backend/.env
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(env_path)

client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

def ask_llm(prompt: str) -> str:
    response = client.messages.create(
        model="claude-3-haiku-20240307",
        max_tokens=1024,
        system="You are a helpful assistant.",
        messages=[{"role": "user", "content": prompt}],
    )
    return response.content[0].text.strip()
