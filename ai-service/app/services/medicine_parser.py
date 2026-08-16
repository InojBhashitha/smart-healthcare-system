"""Medicine line parser and structured prescription information extractor.

Extracts structured fields from raw OCR text lines:
    - medicine name
    - strength (e.g., "500 mg")
    - dosage form (e.g., "capsule", "tablet", "syrup")
    - frequency (e.g., "3 times per day", "twice daily")
    - duration (e.g., "7 days", "2 weeks")
    - quantity (e.g., "21 capsules", "14 tablets")
"""

import re
import logging

logger = logging.getLogger(__name__)

# Pattern for medicine strength units
STRENGTH_PATTERN = re.compile(
    r"(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|iu|%|µg)",
    re.IGNORECASE,
)

# Pattern for duration (e.g., "7 days", "seven days", "2 weeks", "5 days")
DURATION_PATTERN = re.compile(
    r"\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s*(day|days|wk|wks|week|weeks|month|months)\b",
    re.IGNORECASE,
)

# Pattern for quantity (e.g., "Cap # 21", "21 caps", "14 tabs", "#21", "qty 21")
QUANTITY_PATTERN = re.compile(
    r"\b(?:qty|quantity|count|cap|caps|tab|tabs|tablet|tablets)?\s*#\s*(\d+)\b|\b(\d+)\s*(tab|tabs|tablet|tablets|cap|caps|capsule|capsules|vial|vials|bottle|bottles)\b",
    re.IGNORECASE,
)

# Word numbers map
WORD_NUMBERS = {
    "one": "1", "two": "2", "three": "3", "four": "4", "five": "5",
    "six": "6", "seven": "7", "eight": "8", "nine": "9", "ten": "10",
}

# Dosage form keywords and map
DOSAGE_FORM_MAP = {
    "tab": "tablet",
    "tabs": "tablet",
    "tablet": "tablet",
    "tablets": "tablet",
    "cap": "capsule",
    "caps": "capsule",
    "capsule": "capsule",
    "capsules": "capsule",
    "syrup": "syrup",
    "syr": "syrup",
    "susp": "suspension",
    "suspension": "suspension",
    "inj": "injection",
    "injection": "injection",
    "cream": "cream",
    "ointment": "ointment",
    "drops": "drop",
    "drop": "drop",
}

# Frequency map
FREQUENCY_PATTERNS = [
    (r"\b(tds|t\.d\.s|3x|3\s*times|thrice|3\s*tpd)\b", "3 times per day"),
    (r"\b(bd|b\.i\.d|bid|2x|2\s*times|twice)\b", "twice daily"),
    (r"\b(od|o\.d|1x|1\s*time|once|daily)\b", "once daily"),
    (r"\b(qid|q\.i\.d|4x|4\s*times)\b", "4 times per day"),
    (r"\b(hs|h\.s|night|bedtime)\b", "once at bedtime"),
    (r"\b(sos|prn|as\s*needed)\b", "as needed"),
]

# Prefixes/headers to skip
SKIP_PREFIXES = (
    "date", "name", "patient", "doctor", "dr", "dr.", "rx", "prescription",
    "address", "phone", "tel", "tel:", "age", "sex", "gender", "hospital",
    "clinic", "signature", "refill", "diagnosis", "weight", "height",
    "note", "note:", "reg", "reg.", "mbbs", "slmc", "street", "road",
    "colombo", "lanka", "city", "town", "no:", "no.", "sig", "sig:", "sig.",
    "physician", "physician's", "lic", "lic.", "ptr", "ptr.", "s2", "s2."
)


def parse_medicines(raw_text: str) -> list[dict]:
    """Parse OCR text into structured medicine entries.

    Returns list of dicts with:
        name, strength, dosage_form, frequency, duration, quantity, instruction
    """
    lines = raw_text.strip().split("\n")
    medicines: list[dict] = []
    current_medicine: dict | None = None
    pending_brand: str | None = None

    for line in lines:
        line = line.strip()
        if not line or len(line) < 2:
            continue

        # Check for standalone brand name in parentheses e.g. "(Himox)" or "( ( Ethmiox ."
        paren_match = re.match(r"^[\s(]+([a-zA-Z0-9\s]{3,})[\s).]+$", line)
        if paren_match and not line.lower().startswith("amox"):
            pending_brand = paren_match.group(1).strip()
            continue

        medicine = _try_parse_medicine_line(line)

        if medicine:
            if pending_brand:
                medicine["brand_hint"] = pending_brand
                pending_brand = None
            current_medicine = medicine
            medicines.append(current_medicine)
        elif current_medicine:
            # Extract strength if missing in main line e.g. "500mg Cap # 21"
            str_match = STRENGTH_PATTERN.search(line)
            if str_match and not current_medicine.get("strength"):
                current_medicine["strength"] = str_match.group(0)

            # Append instruction/dosage details
            existing = current_medicine.get("instruction") or ""
            full_inst = f"{existing} {line}".strip()
            current_medicine["instruction"] = full_inst
            _enrich_structured_fields(current_medicine, full_inst)

    logger.info("Parsed %d structured medicine entries from OCR text", len(medicines))
    return medicines


def _try_parse_medicine_line(line: str) -> dict | None:
    """Try to parse a single line as a medicine entry with structured fields."""
    # Only strip item numbers e.g. "1." or "2)" or "#1." (not dosage numbers like 500mg)
    cleaned = re.sub(r"^\d+[\s.):\-]+\s*", "", line).strip()
    cleaned = re.sub(r"^#\d+[\s.):\-]*\s*", "", cleaned).strip()
    if not cleaned:
        return None

    lower_line = cleaned.lower()

    # Skip headers, doctor info, address lines, and instruction lines
    if any(lower_line.startswith(prefix) for prefix in SKIP_PREFIXES):
        return None

    if _is_instruction_line(cleaned) and not STRENGTH_PATTERN.search(cleaned):
        return None

    if re.search(r"\b(tel|phone|mbbs|slmc|reg|colombo|street|road|city|lanka|date|age|gender|physician|lic|ptr|s2)\b", lower_line):
        return None

    # Detect dosage form
    dosage_form = _extract_dosage_form(cleaned)

    # Detect strength
    strength_match = STRENGTH_PATTERN.search(cleaned)
    strength = strength_match.group(0) if strength_match else None

    # Detect quantity in line e.g. "Cap # 21"
    quantity = None
    qty_match = QUANTITY_PATTERN.search(cleaned)
    if qty_match:
        q_num = qty_match.group(1) or qty_match.group(2)
        unit = qty_match.group(3) or dosage_form or "capsules"
        quantity = f"{q_num} {unit}".strip()

    # Extract name part
    if strength_match:
        name_part = cleaned[:strength_match.start()].strip().rstrip("-–—.")
        after_text = cleaned[strength_match.end():].strip()
    else:
        name_part = cleaned
        after_text = ""

    # Clean up name part
    name_part = re.sub(r"^(tab|cap|syr|inj|tablets|capsules|susp)\b\.?\s*", "", name_part, flags=re.IGNORECASE).strip()
    name_part = _clean_name(name_part)

    if not name_part or len(name_part) < 2 or name_part.lower() in SKIP_PREFIXES:
        return None

    entry = {
        "name": name_part,
        "strength": strength,
        "dosage_form": dosage_form,
        "frequency": None,
        "duration": None,
        "quantity": quantity,
        "instruction": after_text if after_text else None,
    }

    if after_text:
        _enrich_structured_fields(entry, after_text)

    return entry


def _extract_dosage_form(line: str) -> str | None:
    """Extract standard dosage form from text line."""
    lower = line.lower()
    for kw, std_form in DOSAGE_FORM_MAP.items():
        if re.search(r"\b" + re.escape(kw) + r"\b", lower):
            return std_form
    return None


def _enrich_structured_fields(entry: dict, text: str):
    """Enrich medicine entry with extracted frequency, duration, and quantity."""
    lower = text.lower()

    # Extract Frequency
    if not entry.get("frequency"):
        for pattern, freq_str in FREQUENCY_PATTERNS:
            if re.search(pattern, lower, re.IGNORECASE):
                entry["frequency"] = freq_str
                break

    # Extract Duration
    if not entry.get("duration"):
        dur_match = DURATION_PATTERN.search(text)
        if dur_match:
            dur_num = dur_match.group(1).lower()
            dur_num = WORD_NUMBERS.get(dur_num, dur_num)
            unit = dur_match.group(2).lower()
            if not unit.endswith("s"):
                unit += "s"
            entry["duration"] = f"{dur_num} {unit}"

    # Extract Quantity
    if not entry.get("quantity"):
        qty_match = QUANTITY_PATTERN.search(text)
        if qty_match:
            qty_num = qty_match.group(1) or qty_match.group(2)
            unit = qty_match.group(3) or entry.get("dosage_form") or "capsules"
            entry["quantity"] = f"{qty_num} {unit}"


def _is_instruction_line(line: str) -> bool:
    """Check if a line looks like dosage instructions."""
    keywords = ["take", "apply", "use", "daily", "times", "morning", "night", "before", "after", "meals", "days", "sig:", "sig.", "sig"]
    lower = line.lower()
    return any(kw in lower for kw in keywords)


def _clean_name(name: str) -> str:
    """Clean medicine name string."""
    name = re.sub(r"[.,;:\-–—]+$", "", name).strip()
    name = re.sub(r"\s+", " ", name)
    return name.title()
