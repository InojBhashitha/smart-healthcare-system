"""Smart Healthcare AI Service — FastAPI Application.

Provides AI-powered prescription processing:
    - Image quality assessment
    - OpenCV preprocessing
    - Microsoft TrOCR handwriting recognition
    - RapidFuzz medicine name matching

Run with:
    cd ai-service
    pip install -r requirements.txt
    python main.py
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes import prescription_routes
from app.services.medicine_matcher import MedicineMatcher
from app.services.ocr_service import OcrService

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

# Service singletons
ocr = OcrService(model_name=settings.trocr_model)
matcher = MedicineMatcher()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown lifecycle hooks."""

    # ── Startup ──────────────────────────────────
    logger.info("=" * 50)
    logger.info("Smart Healthcare AI Service starting...")
    logger.info("=" * 50)

    # Load TrOCR model (downloads ~1GB on first run)
    ocr.load_model()

    # Load medicine database for fuzzy matching
    matcher.load_medicines()

    # Inject into route module
    prescription_routes.ocr_service = ocr
    prescription_routes.medicine_matcher = matcher

    logger.info("AI Service ready on http://%s:%d", settings.host, settings.port)

    yield

    # ── Shutdown ─────────────────────────────────
    logger.info("AI Service shutting down...")


# Create FastAPI app
app = FastAPI(
    title="Smart Healthcare AI Service",
    description=(
        "AI-powered prescription processing microservice. "
        "Provides image quality assessment, OpenCV preprocessing, "
        "TrOCR handwriting recognition, and RapidFuzz medicine matching."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow Spring Boot backend to call this service
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(prescription_routes.router)


@app.get("/health", tags=["System"])
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": ocr.is_loaded,
        "medicines_loaded": matcher.medicine_count,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=False,
    )
