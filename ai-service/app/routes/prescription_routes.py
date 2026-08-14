"""Prescription processing API routes."""

import logging
import tempfile

import cv2
import numpy as np
from fastapi import APIRouter, File, HTTPException, UploadFile

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
async def process_prescription(file: UploadFile = File(...)):
    """Full AI prescription processing pipeline.

    Steps:
        1. Read & decode the uploaded image
        2. Check image quality (blur, brightness, contrast)
        3. Preprocess with OpenCV (denoise, enhance, deskew)
        4. Run TrOCR handwriting recognition
        5. Parse extracted text into medicine entries
        6. Fuzzy-match medicine names against the database

    Returns:
        PrescriptionResult with quality report, raw text,
        and list of matched medicines with confidence scores.
    """
    # Read image bytes
    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if image is None:
        raise HTTPException(
            status_code=400,
            detail="Could not decode the uploaded image. "
                   "Please upload a valid JPEG or PNG file.",
        )

    logger.info(
        "Processing prescription image: %s (%dx%d)",
        file.filename,
        image.shape[1],
        image.shape[0],
    )

    # 1. Quality check
    quality_data = quality_checker.check(image)
    quality = QualityReport(**quality_data)

    logger.info(
        "Quality check — acceptable: %s, blur: %.1f, "
        "brightness: %.1f, contrast: %.1f",
        quality.is_acceptable,
        quality.blur_score,
        quality.brightness,
        quality.contrast,
    )

    # 2. Preprocess for TrOCR
    processed = preprocessor.preprocess_for_trocr(image)

    # 3. OCR
    if ocr_service is None or not ocr_service.is_loaded:
        raise HTTPException(
            status_code=503,
            detail="AI model is not loaded yet. Please try again shortly.",
        )

    raw_text = ocr_service.recognize(processed)
    logger.info("OCR extracted %d characters", len(raw_text))

    # 4. Parse medicines from text
    parsed = parse_medicines(raw_text)

    # 5. Fuzzy-match against database
    medicines: list[MedicineMatch] = []

    for entry in parsed:
        match_result = {"matched_generic_name": None,
                        "matched_brand_name": None,
                        "confidence": 0.0}

        if medicine_matcher is not None:
            match_result = medicine_matcher.match(entry["name"])

        medicines.append(
            MedicineMatch(
                name=entry["name"],
                strength=entry.get("strength"),
                instruction=entry.get("instruction"),
                matched_generic_name=match_result["matched_generic_name"],
                matched_brand_name=match_result["matched_brand_name"],
                confidence=match_result["confidence"],
            )
        )

    logger.info(
        "Pipeline complete — %d medicines extracted, raw text: %s",
        len(medicines),
        raw_text[:100],
    )

    return PrescriptionResult(
        raw_text=raw_text,
        quality=quality,
        medicines=medicines,
        medicines_found=len(medicines),
    )


@router.post("/refresh-medicines", summary="Reload medicine database cache")
async def refresh_medicines():
    """Reload the medicine master list from PostgreSQL."""
    if medicine_matcher is None:
        raise HTTPException(
            status_code=503,
            detail="Medicine matcher not initialized.",
        )

    medicine_matcher.load_medicines()

    return {
        "status": "refreshed",
        "medicine_count": medicine_matcher.medicine_count,
    }
