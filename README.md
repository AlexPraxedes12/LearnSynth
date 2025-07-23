# LearnSynth

AI-powered interactive course generator from documents.

## API Endpoints

- `POST /generate` – Upload a document and generate a course outline, flashcards and quizzes.
- `POST /flashcards` – Save generated flashcards. Body should be a JSON array of `{front, back}` objects.
- `GET /flashcards/due` – Retrieve flashcards due for review today.
- `POST /flashcards/{id}/review` – Update a flashcard after review. Body: `{ "feedback": "easy" | "hard" }`.
- `POST /concept-map` – Generate a concept map from text. Body: `{ "text": "..." }`.
- `POST /concept-map/image` – Same as above but returns an image (PNG).
- `POST /export` – Export generated Markdown to `md`, `txt` or `pdf`. Body: `{ "content": "...", "fmt": "md|txt|pdf" }`.
- `POST /tts` – Convert text to speech. Body: `{ "text": "..." }`.

## Running

```bash
uvicorn backend.main:app --reload
```

Create a `.env` file inside the `backend` directory with your Claude API key:

```
ANTHROPIC_API_KEY=your-key-here
```

The React frontend can be served from `frontend/` as usual.
