import os
import openai

openai.api_key = os.getenv('OPENAI_API_KEY')

def ask_llm(prompt: str) -> str:
    response = openai.ChatCompletion.create(
        model='gpt-4',
        messages=[
            {"role": "system", "content": "You are an educational content generator."},
            {"role": "user", "content": prompt}
        ]
    )
    return response['choices'][0]['message']['content']
