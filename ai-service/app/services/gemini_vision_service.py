"""Gemini Multimodal Vision Prescription Extractor.

Extracts structured medical prescription data with near-perfect accuracy from doctor handwriting.
Falls back gracefully to local PaddleOCR + TrOCR pipeline if offline or unconfigured.
"""

import json
import logging
import os
import re
import cv2
import numpy as np
from PIL import Image

logger = logging.getLogger(__name__)

EXTRACTION_PROMPT = """You are an expert clinical pharmacist and medical OCR specialist.
Analyze this medical prescription image carefully and extract all prescription information.

CRITICAL MEDICAL REASONING RULES:
1. Examine doctor cursive handwriting, patient metadata, medication lines, dosage strengths, and doctor instructions.
2. Identify brand names (often written in parentheses e.g. (Himox)) and generic drug names (e.g. Amoxicillin).
3. Extract exact dosage strength (e.g. 500mg, 625mg, 40mg), dosage form (capsule, tablet, syrup), frequency (e.g. 3 times per day, twice daily), duration (e.g. 7 days), quantity (e.g. 21 capsules, # 21), and instructions (Sig).
4. Extract patient info (name, age, gender) and doctor signature/license metadata if visible.

Return ONLY a valid JSON object matching this exact structure:
{
  "raw_text": "Complete transcribed text of the prescription",
  "patient_name": "Patient full name or null",
  "patient_age": "Patient age or null",
  "patient_gender": "M or F or null",
  "doctor_name": "Doctor name or signature text or null",
  "medicines": [
    {
      "name": "Standard drug name (e.g. Amoxicillin)",
      "brand_hint": "Brand name if present (e.g. Himox) or null",
      "strength": "Dosage strength with unit (e.g. 500mg) or null",
      "dosage_form": "tablet | capsule | syrup | injection | cream | drop | null",
      "frequency": "Frequency schedule (e.g. 3 times per day) or null",
      "duration": "Duration (e.g. 7 days) or null",
      "quantity": "Quantity dispensed (e.g. 21 capsules) or null",
      "instruction": "Full dosage instruction (e.g. 1 cap 3x a day for seven days) or null",
      "confidence": 98.0
    }
  ]
}
"""


class GeminiVisionService:
    """Multimodal Vision prescription extractor using Google Gemini."""

    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") or os.getenv("API_KEY")
        self._model = None
        if self.api_key:
            self._init_gemini()

    def _init_gemini(self):
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            self._model = genai.GenerativeModel("gemini-1.5-flash")
            logger.info("Gemini Vision model initialized successfully.")
        except Exception as e:
            logger.warning("Failed to initialize Gemini Vision: %s", e)
            self._model = None

    @property
    def is_available(self) -> bool:
        return self._model is not None or bool(os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY"))

    def extract_prescription(self, image: np.ndarray) -> dict | None:
        """Extract structured prescription data from image numpy array using Gemini Vision."""
        if not self._model:
            self.api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") or os.getenv("API_KEY")
            if self.api_key:
                self._init_gemini()

        if not self._model:
            return None

        try:
            # Convert OpenCV BGR image to PIL RGB Image
            if len(image.shape) == 3:
                rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            else:
                rgb = image
            pil_image = Image.fromarray(rgb)

            logger.info("Calling Gemini Vision API for prescription extraction...")
            response = self._model.generate_content(
                [EXTRACTION_PROMPT, pil_image],
                generation_config={"temperature": 0.1, "response_mime_type": "application/json"}
            )

            response_text = response.text.strip()
            # Clean possible markdown formatting
            if response_text.startswith("```json"):
                response_text = response_text[7:]
            if response_text.startswith("```"):
                response_text = response_text[3:]
            if response_text.endswith("```"):
                response_text = response_text[:-3]

            data = json.loads(response_text.strip())
            logger.info("Gemini Vision extracted %d medicines successfully.", len(data.get("medicines", [])))
            return data

        except Exception as e:
            logger.error("Gemini Vision extraction error: %s", e)
            return None
