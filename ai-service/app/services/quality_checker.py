"""Image quality assessment service.

Evaluates prescription images for blur, brightness, and contrast
to determine if they are suitable for OCR processing.
"""

import cv2
import numpy as np


class QualityChecker:
    """Checks image quality metrics before OCR processing."""

    # Thresholds
    BLUR_THRESHOLD = 50.0       # Laplacian variance; below = too blurry
    BRIGHTNESS_LOW = 40.0       # Mean pixel value; below = too dark
    BRIGHTNESS_HIGH = 220.0     # Above = too bright / washed out
    CONTRAST_THRESHOLD = 30.0   # Std deviation; below = low contrast

    def check(self, image: np.ndarray) -> dict:
        """Evaluate image quality and return a report dict.

        Args:
            image: BGR image as numpy array (from cv2.imread).

        Returns:
            Dict with is_acceptable, blur_score, brightness,
            contrast, and list of issue strings.
        """
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Blur detection via Laplacian variance
        blur_score = cv2.Laplacian(gray, cv2.CV_64F).var()

        # Brightness = mean pixel intensity
        brightness = float(np.mean(gray))

        # Contrast = standard deviation of pixel intensities
        contrast = float(np.std(gray))

        issues: list[str] = []

        if blur_score < self.BLUR_THRESHOLD:
            issues.append(
                f"Image is too blurry (score: {blur_score:.1f}, "
                f"min: {self.BLUR_THRESHOLD})"
            )

        if brightness < self.BRIGHTNESS_LOW:
            issues.append(
                f"Image is too dark (brightness: {brightness:.1f})"
            )
        elif brightness > self.BRIGHTNESS_HIGH:
            issues.append(
                f"Image is overexposed (brightness: {brightness:.1f})"
            )

        if contrast < self.CONTRAST_THRESHOLD:
            issues.append(
                f"Low contrast (contrast: {contrast:.1f}, "
                f"min: {self.CONTRAST_THRESHOLD})"
            )

        return {
            "is_acceptable": len(issues) == 0,
            "blur_score": round(blur_score, 2),
            "brightness": round(brightness, 2),
            "contrast": round(contrast, 2),
            "issues": issues,
        }
