"""PaddleOCR (PP-OCRv5) + Microsoft TrOCR Hybrid Handwritten Processing Service.

Combines PaddleOCR's high-precision text line & region detection with
Microsoft TrOCR (microsoft/trocr-base-handwritten) for end-to-end
handwritten prescription text extraction.
"""

import logging
import cv2
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)


class PaddleTrocrPipeline:
    """Hybrid pipeline using PaddleOCR for line detection and TrOCR for handwriting recognition."""

    def __init__(self, trocr_model_name: str = "microsoft/trocr-base-handwritten"):
        self.trocr_model_name = trocr_model_name
        self.paddle_ocr = None
        self.processor = None
        self.trocr_model = None
        self._loaded = False

    def load_models(self):
        """Lazy load PaddleOCR detector and TrOCR vision encoder-decoder model."""
        try:
            logger.info("Initializing PaddleOCR PP-OCRv5 Text Detector...")
            from paddleocr import PaddleOCR

            # Initialize PaddleOCR detector
            self.paddle_ocr = PaddleOCR(lang="en")
            logger.info("PaddleOCR Text Detector initialized successfully.")

            logger.info("Loading Microsoft TrOCR model: %s ...", self.trocr_model_name)
            from transformers import TrOCRProcessor, VisionEncoderDecoderModel

            self.processor = TrOCRProcessor.from_pretrained(self.trocr_model_name)
            self.trocr_model = VisionEncoderDecoderModel.from_pretrained(self.trocr_model_name)

            self._loaded = True
            logger.info("TrOCR model and processor loaded successfully.")

        except Exception as e:
            logger.error("Failed to initialize PaddleOCR + TrOCR pipeline: %s", e)
            self._loaded = False

    @property
    def is_loaded(self) -> bool:
        return self._loaded

    def preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """Preprocess prescription image for optimal text detection and OCR.

        Applies CLAHE contrast enhancement and subtle denoising.
        """
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
        """Detect text bounding regions/lines using PaddleOCR PP-OCRv5.

        Fallback to contour/projection-based segmentation if PaddleOCR returns no boxes.
        """
        line_crops: list[np.ndarray] = []
        h, w = image.shape[:2]

        if self.paddle_ocr is not None:
            try:
                # PaddleOCR API call for box detection
                results = self.paddle_ocr.ocr(image)
                boxes = []

                if results and results[0]:
                    for item in results[0]:
                        if isinstance(item, (list, tuple)) and len(item) >= 1:
                            pts = np.array(item[0], dtype=np.int32)
                            x_min = max(0, np.min(pts[:, 0]) - 4)
                            x_max = min(w, np.max(pts[:, 0]) + 4)
                            y_min = max(0, np.min(pts[:, 1]) - 4)
                            y_max = min(h, np.max(pts[:, 1]) + 4)
                            box_h = y_max - y_min
                            box_w = x_max - x_min

                            if box_h >= 12 and box_w >= 15:
                                boxes.append((y_min, y_max, x_min, x_max))

                # Sort boxes top-to-bottom by y_min coordinate
                boxes.sort(key=lambda b: b[0])

                for y_min, y_max, x_min, x_max in boxes:
                    crop = image[y_min:y_max, x_min:x_max]
                    line_crops.append(crop)

                if line_crops:
                    logger.info("PaddleOCR detected %d text line regions.", len(line_crops))
                    return line_crops

            except Exception as e:
                logger.warning("PaddleOCR text detection skipped (%s). Using contour line segmenter.", e)

        # Fallback projection-based line segmenter if PaddleOCR yields 0 crops
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
                early_stopping=True,
            )
            text = self.processor.batch_decode(generated_ids, skip_special_tokens=True)[0]
            text = text.strip()

            # Filter hallucinated phrases, repetitive loops, and invalid number noise
            if self._is_hallucination(text) or self._has_repetition_loop(text) or not self._is_valid_text_line(text):
                return ""

            return text

        except Exception as e:
            logger.warning("TrOCR line recognition error: %s", e)
            return ""

    def process_prescription(self, image: np.ndarray) -> str:
        """End-to-end pipeline: Preprocess -> PaddleOCR Line Detection -> TrOCR Recognition."""
        if not self._loaded:
            self.load_models()

        preprocessed = self.preprocess_image(image)
        line_crops = self.detect_line_crops(preprocessed)

        recognized_lines: list[str] = []
        for crop in line_crops[:12]:  # Limit to top 12 lines for efficiency
            line_str = self.recognize_line(crop)
            if line_str and len(line_str) >= 2:
                recognized_lines.append(line_str)

        full_text = "\n".join(recognized_lines).strip()
        logger.info("PaddleOCR + TrOCR pipeline extracted %d lines of text.", len(recognized_lines))
        return full_text

    def _is_hallucination(self, text: str) -> bool:
        """Filter common TrOCR IAM dataset hallucination phrases."""
        hallucinations = [
            "american housewives", "government of australia", "government of america",
            "united states", "housewife", "housewives", "beginning of the beginning",
            "issuing expertise", "quality of the most", "department of health",
            "makati city", "maximum long letter", "sing- recap", "exonday",
            "successful success", "today . june", "delayed to", "delegates",
            "documented", "legend", "market", "application", "chronicling",
            "unsigned's", "russo", "quality history", "common people",
            "first appearance", "in his own", "sipoal"
        ]
        lower = text.lower()
        return any(ph in lower for ph in hallucinations)

    def _is_valid_text_line(self, text: str) -> bool:
        """Check if extracted text is a genuine prescription text line (not noise like '0 0', '0 1', '0-000')."""
        text = text.strip()
        if not text or len(text) < 3:
            return False

        # Require at least 3 alphabetic letters
        letters = [c for c in text if c.isalpha()]
        if len(letters) < 3:
            return False

        return True

    def _is_blank_or_noise(self, line_crop: np.ndarray) -> bool:
        """Check if a crop is completely blank white background without ink."""
        if line_crop is None or line_crop.size == 0:
            return True
        if len(line_crop.shape) == 3:
            gray = cv2.cvtColor(line_crop, cv2.COLOR_RGB2GRAY)
        else:
            gray = line_crop.copy()

        # Check standard deviation / contrast variance
        std_dev = float(np.std(gray))
        if std_dev < 4.0:
            return True

        # Check foreground ink pixel ratio
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        ink_ratio = np.sum(binary > 0) / binary.size
        if ink_ratio < 0.005 or ink_ratio > 0.95:
            return True

        return False

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

        # Ignore outer 3% margin to skip scanner borders
        y_start = int(h_img * 0.03)
        y_end = int(h_img * 0.97)
        x_start = int(w_img * 0.03)
        x_end = int(w_img * 0.97)

        inner = gray[y_start:y_end, x_start:x_end]
        inner_img = image[y_start:y_end, x_start:x_end]

        # CLAHE contrast enhancement
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        enhanced = clahe.apply(inner)

        # Otsu Binarization + Morphological Dilation to form horizontal line boxes
        _, binary = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (35, 5))
        dilated = cv2.dilate(binary, kernel, iterations=2)

        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        boxes = []
        for c in contours:
            x, y, w, h = cv2.boundingRect(c)
            # Filter valid handwritten line dimensions
            if w >= 40 and 14 <= h <= 120:
                y1 = max(0, y - 4)
                y2 = min(inner.shape[0], y + h + 4)
                x1 = max(0, x - 6)
                x2 = min(inner.shape[1], x + w + 6)
                boxes.append((y1, y2, x1, x2))

        # Sort lines top-to-bottom
        boxes.sort(key=lambda b: b[0])

        crops = []
        for y1, y2, x1, x2 in boxes:
            crop = inner_img[y1:y2, x1:x2]
            if crop.shape[0] >= 12 and crop.shape[1] >= 20:
                crops.append(crop)

        if not crops:
            crops.append(image)

        logger.info("Morphological segmenter extracted %d clean text line crops.", len(crops))
        return crops
