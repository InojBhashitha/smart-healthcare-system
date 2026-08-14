# AI Service

Python FastAPI microservice for AI-powered prescription processing.

## Features
- **Image Quality Check** — Blur, brightness, contrast assessment
- **OpenCV Preprocessing** — Denoise, CLAHE, deskew, threshold
- **Microsoft TrOCR** — Handwriting recognition (transformer-based)
- **RapidFuzz Matching** — Fuzzy medicine name matching against PostgreSQL

## Setup

```bash
cd ai-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
python main.py
```

The service starts on `http://localhost:8000`.

> **Note:** The TrOCR model (~1GB) downloads automatically on first run.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/ai/process-prescription` | Full AI prescription pipeline |
| `POST` | `/api/ai/refresh-medicines` | Reload medicine DB cache |
| `GET`  | `/health` | Health check |
| `GET`  | `/docs` | Swagger UI |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `smart_healthcare` | Database name |
| `DB_USERNAME` | `postgres` | Database user |
| `DB_PASSWORD` | `smarthealth123` | Database password |
| `TROCR_MODEL` | `microsoft/trocr-base-handwritten` | HuggingFace model |
| `FUZZY_MATCH_THRESHOLD` | `70` | Min fuzzy match score (0-100) |
