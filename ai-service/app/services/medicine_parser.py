"""Medicine line parser.

Extracts structured medicine information (name, strength, instruction)
from raw OCR text lines using regex patterns and medical header filters.
"""

import re
import logging

logger = logging.getLogger(__name__)

# Patterns for medicine strength units
STRENGTH_PATTERN = re.compile(
    r"(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|iu|%|µg)",
    re.IGNORECASE,
)

# Common dosage instruction keywords
INSTRUCTION_KEYWORDS = [
    "take", "apply", "use", "inject", "inhale",
    "once", "twice", "thrice", "daily", "times",
    "morning", "afternoon", "evening", "night",
    "before", "after", "meals", "food", "bed",
    "tablet", "tablets", "capsule", "capsules",
    "drops", "puffs", "spoon", "teaspoon",
]

# Words to skip — common prescription headers, addresses, doctor credentials
SKIP_PREFIXES = (
    "date", "name", "patient", "doctor", "dr", "dr.", "rx", "prescription",
    "address", "phone", "tel", "tel:", "age", "sex", "gender", "hospital",
    "clinic", "signature", "refill", "diagnosis", "weight", "height",
    "note", "note:", "reg", "reg.", "mbbs", "slmc", "street", "road",
    "colombo", "lanka", "city", "town", "no:", "no."
)


def parse_medicines(raw_text: str) -> list[dict]:
    """Parse OCR text into structured medicine entries.

    Handles various prescription formats:
        - "1. Paracetamol 500mg - Take 1 tablet twice daily"
        - "2. Amoxicillin 250mg"
        - "Vitamin C 500mg"

    Args:
        raw_text: Raw text from OCR recognition.

    Returns:
        List of dicts with keys: name, strength, instruction.
    """
    lines = raw_text.strip().split("\n")
    medicines: list[dict] = []
    current_medicine: dict | None = None

    for line in lines:
        line = line.strip()
        if not line or len(line) < 3:
            continue

        # Check if line looks like a medicine entry
        medicine = _try_parse_medicine_line(line)

        if medicine:
            current_medicine = medicine
            medicines.append(current_medicine)
        elif current_medicine and _is_instruction_line(line):
            # Append as instruction to the previous medicine
            existing = current_medicine.get("instruction", "")
            if existing:
                current_medicine["instruction"] = f"{existing} {line}"
            else:
                current_medicine["instruction"] = line

    logger.info("Parsed %d genuine medicines from OCR text", len(medicines))
    return medicines


def _try_parse_medicine_line(line: str) -> dict | None:
    """Try to parse a single line as a medicine entry."""
    # Remove leading numbering (e.g., "1.", "2)", "#1", "1 .")
    cleaned = re.sub(r"^[\d#]+\s*[.):\-]?\s*", "", line).strip()

    if not cleaned:
        return None

    # Skip header / address / doctor metadata lines
    lower_line = cleaned.lower()
    if any(lower_line.startswith(prefix) for prefix in SKIP_PREFIXES):
        return None

    # Skip lines containing typical non-medicine patterns (e.g. phone numbers, dates, street addresses)
    if re.search(r"\b(tel|phone|mbbs|slmc|reg|colombo|street|road|city|lanka|date|age|gender)\b", lower_line):
        return None

    # Try to find strength pattern in the line
    strength_match = STRENGTH_PATTERN.search(cleaned)

    if strength_match:
        strength_start = strength_match.start()
        name_part = cleaned[:strength_start].strip().rstrip("-–—.")
        strength = strength_match.group(0)

        # Remaining text after strength
        after_strength = cleaned[strength_match.end():].strip()
        instruction = None

        if after_strength:
            after_strength = re.sub(r"^[\s\-–—,;:]+", "", after_strength).strip()
            if after_strength and _is_instruction_line(after_strength):
                instruction = after_strength

        if name_part and len(name_part) >= 2 and not name_part.lower().startswith(SKIP_PREFIXES):
            return {
                "name": _clean_name(name_part),
                "strength": strength,
                "instruction": instruction,
            }

    return None


def _is_instruction_line(line: str) -> bool:
    """Check if a line looks like a dosage instruction."""
    lower = line.lower()
    return any(kw in lower for kw in INSTRUCTION_KEYWORDS)


def _clean_name(name: str) -> str:
    """Clean up a medicine name string."""
    name = re.sub(r"[.,;:\-–—]+$", "", name).strip()
    name = re.sub(r"\s+", " ", name)
    return name.title()

