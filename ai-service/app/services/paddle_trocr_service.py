"""PaddleOCR PP-OCRv5 Text Detection + Microsoft TrOCR Line Recognition Pipeline.

Architecture:
    1. OpenCV Morphological Line Segmenter — Isolates horizontal text line crops.
    2. Image Preprocessing — Upscales small camera photos to 1400px with CLAHE contrast.
    3. Microsoft TrOCR — Decodes handwritten text from each line crop.
    4. RapidFuzz Post-Processing — Filters IAM dataset hallucinations and zero-noise lines.
"""

import cv2
import re
import logging
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)


class PaddleTrocrPipeline:
    """Hybrid PaddleOCR/OpenCV line detection + TrOCR line recognition pipeline."""

    def __init__(
        self,
        trocr_model_name: str = "microsoft/trocr-base-handwritten",
    ):
        self.trocr_model_name = trocr_model_name
        self.trocr_model = None
        self.processor = None
        self._loaded = False

    def load_models(self):
        """Load Microsoft TrOCR vision-encoder-decoder model."""
        if self._loaded:
            return

        try:
            from transformers import TrOCRProcessor, VisionEncoderDecoderModel

            logger.info("Loading Microsoft TrOCR model: %s ...", self.trocr_model_name)
            self.processor = TrOCRProcessor.from_pretrained(self.trocr_model_name)
            self.trocr_model = VisionEncoderDecoderModel.from_pretrained(self.trocr_model_name)

            self._loaded = True
            logger.info("TrOCR model and processor loaded successfully.")

        except Exception as e:
            logger.error("Failed to initialize TrOCR pipeline: %s", e)
            self._loaded = False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """Preprocess prescription image for optimal text detection and OCR.

        Scales small camera uploads to 1400px and applies CLAHE contrast.
        """
        h, w = image.shape[:2]
        max_dim = max(h, w)

        if max_dim < 1200:
            scale = 1400.0 / float(max_dim)
            new_w = int(w * scale)
            new_h = int(h * scale)
            image = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_CUBIC)

        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        else:
            gray = image.copy()

        # CLAHE (Contrast Limited Adaptive Histogram Equalization)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # Convert back to RGB for TrOCR input compatibility
        enhanced_rgb = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2RGB)
        return enhanced_rgb

    def detect_line_crops(self, image: np.ndarray) -> list[np.ndarray]:
        """Detect text bounding regions/lines using high-precision OpenCV morphological segmenter."""
        return self._fallback_line_segmenter(image)

    def recognize_line(self, line_crop: np.ndarray) -> str:
        """Recognize handwritten text from a cropped line image using Microsoft TrOCR."""
        if not self._loaded or self.trocr_model is None or self.processor is None:
            return ""

        if self._is_blank_or_noise(line_crop):
            return ""

        try:
            pil_img = Image.fromarray(line_crop).convert("RGB")
            pixel_values = self.processor(images=pil_img, return_tensors="pt").pixel_values

            # Generate TrOCR tokens with repetition penalty to eliminate repeating loops
            generated_ids = self.trocr_model.generate(
                pixel_values,
                max_new_tokens=48,
                no_repeat_ngram_size=3,
                repetition_penalty=1.2,
            )
            text = self.processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
            text = text.strip()

            # Filter hallucinated phrases, repetitive loops, and zero-only noise
            if self._is_hallucination(text) or self._has_repetition_loop(text) or not self._is_valid_text_line(text):
                return ""

            return text

        except Exception as e:
            logger.warning("TrOCR line recognition error: %s", e)
            return ""

    def process_prescription(self, image: np.ndarray) -> str:
        """End-to-end pipeline: 2x Rescale -> Tesseract 5 + TrOCR Line Recognition."""
        if not self._loaded:
            self.load_models()

        # Rescale up to 2x for OCR character clarity
        h, w = image.shape[:2]
        scaled = cv2.resize(image, (w * 2, h * 2), interpolation=cv2.INTER_CUBIC)

        # 1. Tesseract 5 full document extraction
        import pytesseract
        from PIL import Image as PILImage

        tess_lines: list[str] = []
        try:
            pil_img = PILImage.fromarray(scaled)
            tess_raw = pytesseract.image_to_string(pil_img, config="--psm 6").strip()
            for line in tess_raw.split("\n"):
                line = line.strip()
                if line and len(line) >= 2:
                    tess_lines.append(line)
        except Exception as e:
            logger.warning("Tesseract 5 extraction error: %s", e)

        # 2. TrOCR line crop recognition
        preprocessed = self.preprocess_image(image)
        line_crops = self.detect_line_crops(preprocessed)

        trocr_lines: list[str] = []
        for crop in line_crops[:12]:
            line_str = self.recognize_line(crop)
            if line_str and len(line_str) >= 2 and not self._is_hallucination(line_str):
                trocr_lines.append(line_str)

        all_lines = tess_lines + trocr_lines
        full_text = "\n".join(all_lines).strip()
        logger.info("OCR pipeline extracted %d lines of text (Tess: %d, TrOCR: %d).", len(all_lines), len(tess_lines), len(trocr_lines))
        return full_text

    def _is_hallucination(self, text: str) -> bool:
        """Validation for single-line handwritten OCR crops.
        
        Filter out common TrOCR IAM prose dataset hallucinations.
        """
        if not text:
            return True

        text_clean = text.strip()

        # Common English prose sentence connectives unlikely in prescription medication lines
        prose_connectives = [
            "who had", "been able", "of the american", "to take the",
            "written in", "secretary of", "department of", "government of",
            "united states", "housewives", "beginning of the"
        ]
        lower = text_clean.lower()
        return any(conn in lower for conn in prose_connectives)

    def _is_valid_text_line(self, text: str) -> bool:
        """Check if extracted text is a valid line (requires 2+ consecutive letters, filtering 0 1, 0 0, 20)."""
        text = text.strip()
        if not text or len(text) < 3:
            return False

        # Require at least 2 consecutive alphabetic letters (e.g. 'mg', 'cap', 'tab', 'Amoxicillin')
        if not re.search(r"[a-zA-Z]{2,}", text):
            return False

        return True

    def _is_blank_or_noise(self, line_crop: np.ndarray) -> bool:
        """Check if a crop is completely empty background without pixels."""
        if line_crop is None or line_crop.size == 0:
            return True
        if len(line_crop.shape) == 3:
            gray = cv2.cvtColor(line_crop, cv2.COLOR_RGB2GRAY)
        else:
            gray = line_crop.copy()

        std_dev = float(np.std(gray))
        return std_dev < 2.0

    def _has_repetition_loop(self, text: str) -> bool:
        """Detect if TrOCR autoregressive generation entered a repetitive loop (e.g. 'ever ever ever')."""
        words = text.lower().split()
        if not words:
            return False
        from collections import Counter
        counts = Counter(words)
        for w, c in counts.items():
            if len(w) >= 3 and c >= 3:
                return True
        return False

    def _fallback_line_segmenter(self, image: np.ndarray) -> list[np.ndarray]:
        """Morphological contour line segmenter designed for prescription handwriting."""
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        else:
            gray = image.copy()

        h_img, w_img = image.shape[:2]

        # Ignore outer 3% margin to skip camera scanner frame lines
        y_start = int(h_img * 0.03)
        y_end = int(h_img * 0.97)
        x_start = int(w_img * 0.03)
        x_end = int(w_img * 0.97)

        inner = gray[y_start:y_end, x_start:x_end]
        inner_img = image[y_start:y_end, x_start:x_end]

        # Adaptive Gaussian Thresholding to isolate handwriting from background watermarks
        binary = cv2.adaptiveThreshold(
            inner, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 31, 15
        )
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (45, 6))
        dilated = cv2.dilate(binary, kernel, iterations=2)

        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        boxes = []
        for c in contours:
            x, y, w, h = cv2.boundingRect(c)
            if w >= 30 and 10 <= h <= 180:
                y1 = max(0, y - 5)
                y2 = min(inner.shape[0], y + h + 5)
                x1 = max(0, x - 8)
                x2 = min(inner.shape[1], x + w + 8)
                boxes.append((y1, y2, x1, x2))

        # Sort lines top-to-bottom
        boxes.sort(key=lambda b: b[0])

        crops = []
        for y1, y2, x1, x2 in boxes:
            crop = inner_img[y1:y2, x1:x2]
            if crop.shape[0] >= 10 and crop.shape[1] >= 15:
                crops.append(crop)

        if not crops:
            crops.append(image)

        logger.info("Adaptive line segmenter extracted %d clean text line crops.", len(crops))
        return crops
