"""OpenCV image preprocessing pipeline.

Applies a series of transformations to improve OCR accuracy
and performance on prescription images.
"""

import cv2
import numpy as np


class ImagePreprocessor:
    """Preprocesses prescription images for optimal OCR results."""

    MAX_DIMENSION = 800  # Resize large images for 10x faster CPU processing

    def resize_if_needed(self, image: np.ndarray) -> np.ndarray:
        """Resize image if dimensions exceed MAX_DIMENSION.

        Keeps aspect ratio intact while speeding up CPU operations drastically.
        """
        h, w = image.shape[:2]
        if max(h, w) > self.MAX_DIMENSION:
            scale = self.MAX_DIMENSION / float(max(h, w))
            new_w = int(w * scale)
            new_h = int(h * scale)
            return cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
        return image

    def preprocess(self, image: np.ndarray) -> np.ndarray:
        """Apply the full preprocessing pipeline for Tesseract.

        Steps:
            1. Downscale to max dimension (for 10x speed boost)
            2. Grayscale conversion
            3. CLAHE contrast enhancement
            4. Adaptive thresholding
        """
        resized = self.resize_if_needed(image)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

        # CLAHE contrast enhancement
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # Deskew
        deskewed = self._deskew(enhanced)

        # Adaptive thresholding
        binary = cv2.adaptiveThreshold(
            deskewed,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            blockSize=15,
            C=11,
        )

        return binary

    def preprocess_for_trocr(self, image: np.ndarray) -> np.ndarray:
        """Lighter preprocessing for TrOCR.

        Args:
            image: BGR image as numpy array.

        Returns:
            RGB image scaled and deskewed for TrOCR input.
        """
        resized = self.resize_if_needed(image)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

        # CLAHE for contrast
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # Deskew
        deskewed = self._deskew(enhanced)

        # Convert back to RGB for TrOCR
        rgb = cv2.cvtColor(deskewed, cv2.COLOR_GRAY2RGB)
        return rgb

    def _deskew(self, image: np.ndarray) -> np.ndarray:
        """Correct image tilt using minimum area rectangle on contours."""
        _, thresh = cv2.threshold(
            image, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
        )

        coords = np.column_stack(np.where(thresh > 0))
        if len(coords) < 10:
            return image

        angle = cv2.minAreaRect(coords)[-1]
        if angle < -45:
            angle = -(90 + angle)
        else:
            angle = -angle

        if abs(angle) < 0.5 or abs(angle) > 30:
            return image

        (h, w) = image.shape[:2]
        center = (w // 2, h // 2)
        rotation_matrix = cv2.getRotationMatrix2D(center, angle, 1.0)
        rotated = cv2.warpAffine(
            image,
            rotation_matrix,
            (w, h),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )

        return rotated

