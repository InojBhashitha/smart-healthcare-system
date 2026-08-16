"""Unified Modular OCR Service supporting multiple handwriting recognition engines.

Engines:
    1. "paddle_trocr" — PaddleOCR PP-OCRv5 Line Detection + Microsoft TrOCR
    2. "hybrid_tesseract_trocr" — Tesseract 5 + TrOCR baseline
"""

import logging
import numpy as np
from PIL import Image

from app.services.paddle_trocr_service import PaddleTrocrPipeline

logger = logging.getLogger(__name__)


class OcrService:
    """Unified OCR manager allowing engine switching between PaddleOCR+TrOCR and Baseline."""

    def __init__(self, model_name: str = "microsoft/trocr-base-handwritten"):
        self.model_name = model_name
        self.paddle_trocr_pipeline = PaddleTrocrPipeline(trocr_model_name=model_name)
        self.processor = None
        self.model = None
        self._loaded = False

    def load_model(self):
        """Load TrOCR processor, TrOCR vision model, and PaddleOCR detector."""
        try:
            from transformers import TrOCRProcessor, VisionEncoderDecoderModel

            logger.info("Loading TrOCR base handwritten model: %s ...", self.model_name)
            self.processor = TrOCRProcessor.from_pretrained(self.model_name)
            self.model = VisionEncoderDecoderModel.from_pretrained(self.model_name)

            logger.info("Initializing PaddleOCR + TrOCR pipeline...")
            self.paddle_trocr_pipeline.load_models()

            self._loaded = True
            logger.info("All OCR engines loaded successfully.")

        except Exception as e:
            logger.error("Failed to load OCR models: %s", e)
            self._loaded = False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def recognize(self, image: np.ndarray, engine: str = "paddle_trocr") -> str:
        """Run OCR using the specified engine.

        Args:
            image: Preprocessed RGB image numpy array.
            engine: "paddle_trocr" or "hybrid_tesseract_trocr".

        Returns:
            Extracted text string.
        """
        engine_clean = (engine or "paddle_trocr").lower().strip()

        if engine_clean == "paddle_trocr" and self.paddle_trocr_pipeline.is_loaded:
            try:
                text = self.paddle_trocr_pipeline.process_prescription(image)
                if text:
                    return text
            except Exception as e:
                logger.warning("PaddleOCR+TrOCR pipeline failed, falling back to hybrid: %s", e)

        # Baseline Hybrid Tesseract + TrOCR
        return self._recognize_hybrid_tesseract(image)

    def _recognize_hybrid_tesseract(self, image: np.ndarray) -> str:
        """Baseline hybrid Tesseract + TrOCR recognition."""
        import pytesseract

        tess_text = ""
        try:
            pil_img = Image.fromarray(image)
            tess_text = pytesseract.image_to_string(pil_img, config="--psm 6").strip()
        except Exception as e:
            logger.error("Tesseract error: %s", e)

        trocr_lines = []
        if self._loaded and self.model is not None and self.processor is not None:
            try:
                line_crops = self.paddle_trocr_pipeline._fallback_line_segmenter(image)
                for crop in line_crops[:6]:
                    pil_crop = Image.fromarray(crop).convert("RGB")
                    px = self.processor(images=pil_crop, return_tensors="pt").pixel_values
                    gids = self.model.generate(px, max_new_tokens=64)
                    line_str = self.processor.batch_decode(gids, skip_special_tokens=True)[0].strip()
                    if line_str and len(line_str) < 60 and not self.paddle_trocr_pipeline._is_hallucination(line_str):
                        trocr_lines.append(line_str)
            except Exception as e:
                logger.warning("TrOCR baseline line error: %s", e)

        trocr_text = "\n".join(trocr_lines).strip()
        combined = []
        if tess_text:
            combined.append(tess_text)
        if trocr_text:
            combined.append(trocr_text)

        result = "\n".join(combined).strip()
        return result if result else tess_text
