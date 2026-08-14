"""Hybrid OCR service (Tesseract + Microsoft TrOCR).

Combines fast, layout-aware Tesseract 5 text extraction with
Microsoft TrOCR for fine-grained handwriting recognition.
"""

import logging
from PIL import Image
import numpy as np
import pytesseract

logger = logging.getLogger(__name__)


class OcrService:
    """Hybrid OCR combining Tesseract and TrOCR."""

    def __init__(self, model_name: str):
        self.model_name = model_name
        self.processor = None
        self.model = None
        self._loaded = False

    def load_model(self):
        """Load the TrOCR model and processor."""
        try:
            from transformers import (
                TrOCRProcessor,
                VisionEncoderDecoderModel,
            )

            logger.info("Loading TrOCR model: %s ...", self.model_name)

            self.processor = TrOCRProcessor.from_pretrained(self.model_name)
            self.model = VisionEncoderDecoderModel.from_pretrained(self.model_name)

            self._loaded = True
            logger.info("TrOCR model loaded successfully")

        except Exception as e:
            logger.error("Failed to load TrOCR model: %s", e)
            self._loaded = False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def recognize(self, image: np.ndarray) -> str:
        """Run hybrid OCR on a preprocessed image.

        1. Runs fast Tesseract OCR (< 1 second)
        2. Segments image into clean text line crops and runs TrOCR
        3. Merges text outputs
        """
        # 1. Fast Tesseract OCR baseline
        tess_text = self._recognize_tesseract(image)

        # 2. If TrOCR is loaded, run TrOCR on line crops
        trocr_text = ""
        if self._loaded:
            try:
                lines = self._segment_lines(image)
                # Limit max line crops to 6 to keep CPU inference under 3 seconds
                lines = lines[:6]
                trocr_lines = []
                for line_img in lines:
                    line_str = self._recognize_line(line_img)
                    # Filter out hallucinated text lines (longer than 50 chars or weird tokens)
                    if line_str and len(line_str) < 50 and not self._is_hallucination(line_str):
                        trocr_lines.append(line_str)
                trocr_text = "\n".join(trocr_lines)
            except Exception as e:
                logger.warn("TrOCR line processing skipped: %s", e)

        # Combine results
        combined = []
        if tess_text:
            combined.append(tess_text)
        if trocr_text:
            combined.append(trocr_text)

        result = "\n".join(combined).strip()
        return result if result else tess_text

    def _recognize_tesseract(self, image: np.ndarray) -> str:
        """Run fast Tesseract 5 OCR."""
        try:
            pil_img = Image.fromarray(image)
            text = pytesseract.image_to_string(pil_img, config="--psm 6")
            return text.strip()
        except Exception as e:
            logger.error("Tesseract extraction error: %s", e)
            return ""

    def _recognize_line(self, line_image: np.ndarray) -> str:
        """Recognize text from a single line image via TrOCR."""
        pil_image = Image.fromarray(line_image).convert("RGB")
        pixel_values = self.processor(
            images=pil_image, return_tensors="pt"
        ).pixel_values
        generated_ids = self.model.generate(pixel_values, max_new_tokens=64)
        text = self.processor.batch_decode(
            generated_ids, skip_special_tokens=True
        )[0]
        return text.strip()

    def _is_hallucination(self, text: str) -> bool:
        """Filter out common TrOCR hallucination phrases."""
        hallucination_phrases = [
            "american housewives", "government of australia",
            "united states", "housewife", "beginning of the beginning",
            "issuing expertise", "quality of the most"
        ]
        lower = text.lower()
        return any(phrase in lower for phrase in hallucination_phrases)

    def _segment_lines(self, image: np.ndarray) -> list[np.ndarray]:
        """Segment an image into individual text line crops."""
        import cv2

        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        _, binary = cv2.threshold(
            gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
        )

        h_projection = np.sum(binary, axis=1)
        threshold = np.max(h_projection) * 0.08
        in_line = False
        lines: list[np.ndarray] = []
        start = 0

        for i, val in enumerate(h_projection):
            if val > threshold and not in_line:
                start = i
                in_line = True
            elif val <= threshold and in_line:
                in_line = False
                y1 = max(0, start - 4)
                y2 = min(image.shape[0], i + 4)
                # Only keep line crops that are text-like (height between 15px and 120px)
                if 15 <= (y2 - y1) <= 120:
                    lines.append(image[y1:y2, :])

        return lines

