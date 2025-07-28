# LearnSynth

AI-powered interactive course generator from documents.

## API Endpoints

- `POST /upload-content` – Upload a `.txt` or `.pdf` file and extract the cleaned text.
- `POST /analyze` – Get a summary and main topics for a piece of text.
- `POST /study-mode` – Generate flashcards, concept map or exercises from text. Body: `{ "text": "...", "mode": "flashcards|concept_map|exercises" }`.
- `POST /review/{id}` – Update flashcard progress in the spaced repetition system. Body: `{ "feedback": "easy" | "hard" }`.
- `POST /speak` – Convert text to an MP3 audio file. Body: `{ "text": "..." }`.
- `POST /export` – Export content to `md`, `txt` or `pdf`. Body: `{ "content": "...", "fmt": "md|txt|pdf" }`.

## Running

```bash
uvicorn backend.main:app --reload
```

Create a `.env` file inside the `backend` directory with your Claude API key:

```
ANTHROPIC_API_KEY=your-key-here
```

The React frontend can be served from `frontend/` as usual.
