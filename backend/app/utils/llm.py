import os
from pathlib import Path
from dotenv import load_dotenv
import anthropic

# Load API key from backend/.env
env_path = Path(__file__).resolve().parents[2] / '.env'
load_dotenv(env_path)

client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

def ask_llm(prompt: str) -> str:
    response = client.completions.create(
        model='claude-2',
        max_tokens_to_sample=1024,
        prompt=f"{anthropic.HUMAN_PROMPT} {prompt} {anthropic.AI_PROMPT}"
    )
    return response.completion.strip()
