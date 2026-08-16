"""OpenCV image preprocessing pipeline.

Applies a series of transformations to improve OCR accuracy
and performance on prescription images.
"""

import cv2
import numpy as np


class ImagePreprocessor:
    """Preprocesses prescription images for optimal OCR results."""

    TARGET_DIMENSION = 1400  # Optimal dimension for handwriting TrOCR line recognition

    def resize_for_trocr(self, image: np.ndarray) -> np.ndarray:
        """Scale image to optimal dimension for TrOCR line recognition.

        Ensures text lines are sufficiently tall (~25-40px) for vision transformers.
        """
        h, w = image.shape[:2]
        max_dim = max(h, w)

        if max_dim < 1000:
            scale = float(self.TARGET_DIMENSION) / float(max_dim)
            new_w = int(w * scale)
            new_h = int(h * scale)
            return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
        elif max_dim > 1800:
            scale = 1600.0 / float(max_dim)
            new_w = int(w * scale)
            new_h = int(h * scale)
            return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)

        return image

    def preprocess_for_trocr(self, image: np.ndarray) -> np.ndarray:
        """High-clarity preprocessing for TrOCR.

        Args:
            image: BGR image as numpy array.

        Returns:
            RGB image scaled and enhanced for TrOCR input.
        """
        resized = self.resize_for_trocr(image)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

        # CLAHE for contrast enhancement
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # Convert back to RGB for TrOCR
        rgb = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2RGB)
        return rgb

    def preprocess(self, image: np.ndarray) -> np.ndarray:
        """Standard preprocessing."""
        return self.preprocess_for_trocr(image)
