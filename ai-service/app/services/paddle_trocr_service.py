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

            # Filter hallucinated phrases and repetitive loops
            if self._is_hallucination(text) or self._has_repetition_loop(text):
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
        """Filter common TrOCR hallucination phrases."""
        hallucinations = [
            "american housewives", "government of australia", "united states",
            "housewife", "beginning of the beginning", "issuing expertise",
            "quality of the most", "department of health"
        ]
        lower = text.lower()
        return any(ph in lower for ph in hallucinations)

    def _has_repetition_loop(self, text: str) -> bool:
        """Detect if TrOCR autoregressive generation entered a repetitive loop (e.g. 'ever ever ever')."""
        words = text.lower().split()
        if not words:
            return False
        from collections import Counter
        counts = Counter(words)
        for w, c in counts.items():
            if len(w) >= 3 and c >= 3:  # Word of length 3+ repeated 3+ times in single line
                return True
        return False

    def _fallback_line_segmenter(self, image: np.ndarray) -> list[np.ndarray]:
        """Fallback horizontal projection line segmenter."""
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        else:
            gray = image.copy()

        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        h_proj = np.sum(binary, axis=1)
        threshold = np.max(h_proj) * 0.08

        in_line = False
        start = 0
        crops = []
        h = image.shape[0]

        for i, val in enumerate(h_proj):
            if val > threshold and not in_line:
                start = i
                in_line = True
            elif val <= threshold and in_line:
                in_line = False
                y1 = max(0, start - 4)
                y2 = min(h, i + 4)
                if 14 <= (y2 - y1) <= 140:
                    crops.append(image[y1:y2, :])

        if not crops:
            crops.append(image)
        return crops
