from app.utils.llm import ask_llm

def generate_course(text_bytes):
    text = text_bytes.decode('utf-8')
    prompt = f"""
You are an AI that generates learning material. Given this text:
{text}
Create:
- A course outline (3 modules)
- 2 flashcards per module
- 2 multiple choice questions per module with answers and explanations
Format it in Markdown.
"""
    return {'course': ask_llm(prompt)}
