"""Pydantic response/request schemas for the AI service API."""

from pydantic import BaseModel


class QualityReport(BaseModel):
    """Image quality assessment results."""

    is_acceptable: bool
    blur_score: float
    brightness: float
    contrast: float
    issues: list[str]


class MedicineMatch(BaseModel):
    """A single medicine extracted from the prescription."""

    name: str
    strength: str | None = None
    instruction: str | None = None
    matched_generic_name: str | None = None
    matched_brand_name: str | None = None
    confidence: float = 0.0


class PrescriptionResult(BaseModel):
    """Complete result from processing a prescription image."""

    raw_text: str
    quality: QualityReport
    medicines: list[MedicineMatch]
    medicines_found: int
