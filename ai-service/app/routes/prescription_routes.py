"""Prescription processing API routes."""

import logging
import cv2
import numpy as np
from fastapi import APIRouter, File, HTTPException, Query, UploadFile

from app.schemas import MedicineMatch, PrescriptionResult, QualityReport
from app.services.image_preprocessor import ImagePreprocessor
from app.services.medicine_parser import parse_medicines
from app.services.quality_checker import QualityChecker

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["AI Prescription Processing"])

# Shared service instances (injected at startup from main.py)
quality_checker = QualityChecker()
preprocessor = ImagePreprocessor()
ocr_service = None        # Set by main.py after model load
medicine_matcher = None    # Set by main.py after DB load


@router.post(
    "/process-prescription",
    response_model=PrescriptionResult,
    summary="Process a prescription image through the full AI pipeline",
)
async def process_prescription(
    file: UploadFile = File(...),
    engine: str = Query("paddle_trocr", description="OCR Engine: paddle_trocr or hybrid_tesseract_trocr"),
):
    """Full AI prescription processing pipeline.

    Steps:
        1. Read & decode uploaded image
        2. Quality check (blur, brightness, contrast)
        3. Preprocess with OpenCV (CLAHE enhancement)
        4. Run Handwritten OCR (PaddleOCR PP-OCRv5 line detection + TrOCR)
        5. Extract structured fields (name, strength, form, frequency, duration, qty)
        6. RapidFuzz medicine matching against database
    """
    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if image is None:
        raise HTTPException(
            status_code=400,
            detail="Could not decode the uploaded image. Please upload a valid JPEG or PNG file.",
        )

    logger.info("Processing prescription image: %s (%dx%d) using engine: %s", file.filename, image.shape[1], image.shape[0], engine)

    # 1. Quality check
    quality_data = quality_checker.check(image)
    quality = QualityReport(**quality_data)

    # 2. Preprocess for OCR
    processed = preprocessor.preprocess_for_trocr(image)

    # 3. Run OCR
    if ocr_service is None or not ocr_service.is_loaded:
        raise HTTPException(
            status_code=503,
            detail="AI model is not loaded yet. Please try again shortly.",
        )

    raw_text = ocr_service.recognize(processed, engine=engine)
    logger.info("OCR extracted %d characters", len(raw_text))

    # 4. Parse medicines with structured field extraction
    parsed = parse_medicines(raw_text)

    # 5. Fuzzy-match against database
    medicines: list[MedicineMatch] = []

    for entry in parsed:
        match_result = {
            "matched_generic_name": None,
            "matched_brand_name": None,
            "confidence": 0.0,
        }

        if medicine_matcher is not None:
            brand_hint = entry.get("brand_hint")
            if brand_hint:
                match_result = medicine_matcher.match(brand_hint)
            if not match_result.get("matched_generic_name"):
                match_result = medicine_matcher.match(entry["name"])

        medicines.append(
            MedicineMatch(
                name=entry["name"],
                strength=entry.get("strength"),
                dosage_form=entry.get("dosage_form"),
                frequency=entry.get("frequency"),
                duration=entry.get("duration"),
                quantity=entry.get("quantity"),
                instruction=entry.get("instruction"),
                matched_generic_name=match_result["matched_generic_name"],
                matched_brand_name=match_result["matched_brand_name"],
                confidence=match_result["confidence"],
            )
        )

    logger.info("Pipeline complete — %d medicines extracted.", len(medicines))

    return PrescriptionResult(
        ocr_engine=engine,
        raw_text=raw_text,
        quality=quality,
        medicines=medicines,
        medicines_found=len(medicines),
    )


@router.post("/refresh-medicines", summary="Reload medicine database cache")
async def refresh_medicines():
    """Reload the medicine master list from PostgreSQL."""
    if medicine_matcher is None:
        raise HTTPException(status_code=503, detail="Medicine matcher not initialized.")

    medicine_matcher.load_medicines()
    return {
        "status": "refreshed",
        "medicine_count": medicine_matcher.medicine_count,
    }
