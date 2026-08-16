"""Prescription processing API routes."""

import logging
import cv2
import numpy as np
from fastapi import APIRouter, File, HTTPException, Query, UploadFile

from app.schemas import MedicineMatch, PrescriptionResult, QualityReport
from app.services.image_preprocessor import ImagePreprocessor
from app.services.medicine_parser import parse_medicines
from app.services.quality_checker import QualityChecker
from app.services.gemini_vision_service import GeminiVisionService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/ai", tags=["AI Prescription Processing"])

# Shared service instances (injected at startup from main.py)
quality_checker = QualityChecker()
preprocessor = ImagePreprocessor()
gemini_vision = GeminiVisionService()
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
        3. Multimodal Vision Extractor (Gemini Vision) with local OCR fallback
        4. Structured fields & PostgreSQL database drug linking
    """
    contents = await file.read()
    np_arr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

    if image is None:
        raise HTTPException(
            status_code=400,
            detail="Could not decode the uploaded image. Please upload a valid JPEG or PNG file.",
        )

    logger.info("Processing prescription image: %s (%dx%d)", file.filename, image.shape[1], image.shape[0])

    # 1. Quality check
    quality_data = quality_checker.check(image)
    quality = QualityReport(**quality_data)

    # 2. Try Gemini Vision Extractor first if configured
    if gemini_vision.is_available:
        gemini_result = gemini_vision.extract_prescription(image)
        if gemini_result and gemini_result.get("medicines"):
            logger.info("Prescription successfully extracted via Gemini Vision!")
            medicines = []
            for item in gemini_result["medicines"]:
                med_name = item.get("name") or "Medication"
                brand_hint = item.get("brand_hint")

                match_res = {"matched_generic_name": None, "matched_brand_name": None, "confidence": 0.0}
                if medicine_matcher:
                    if brand_hint:
                        match_res = medicine_matcher.match(brand_hint)
                    if not match_res.get("matched_generic_name"):
                        match_res = medicine_matcher.match(med_name)

                medicines.append(
                    MedicineMatch(
                        name=med_name,
                        strength=item.get("strength"),
                        dosage_form=item.get("dosage_form"),
                        frequency=item.get("frequency"),
                        duration=item.get("duration"),
                        quantity=str(item.get("quantity")) if item.get("quantity") else None,
                        instruction=item.get("instruction"),
                        matched_generic_name=match_res["matched_generic_name"] or med_name,
                        matched_brand_name=match_res["matched_brand_name"] or brand_hint or med_name,
                        confidence=max(item.get("confidence", 95.0), match_res["confidence"]),
                    )
                )

            return PrescriptionResult(
                ocr_engine="gemini_vision",
                raw_text=gemini_result.get("raw_text", ""),
                quality=quality,
                medicines=medicines,
                medicines_found=len(medicines),
            )

    # 3. Fallback to Local Preprocessing + OCR Pipeline
    processed = preprocessor.preprocess_for_trocr(image)

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
        name = entry["name"]
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
                match_result = medicine_matcher.match(name)

        conf = match_result.get("confidence", 0.0)
        has_strength = bool(entry.get("strength"))
        has_dosage_form = bool(entry.get("dosage_form"))

        # Generalized medical validation: Retain if matched drug (>=70%), or has valid strength/form
        is_valid_med = (conf >= 70.0) or has_strength or has_dosage_form
        if not is_valid_med:
            logger.info("Dropping non-medical noise candidate: %s (Conf: %.1f%%)", name, conf)
            continue

        medicines.append(
            MedicineMatch(
                name=name,
                strength=entry.get("strength"),
                dosage_form=entry.get("dosage_form"),
                frequency=entry.get("frequency"),
                duration=entry.get("duration"),
                quantity=entry.get("quantity"),
                instruction=entry.get("instruction"),
                matched_generic_name=match_result["matched_generic_name"],
                matched_brand_name=match_result["matched_brand_name"],
                confidence=conf,
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
