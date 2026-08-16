"""RapidFuzz medicine name matcher.

Fuzzy-matches OCR-recognized medicine names against the PostgreSQL
master medicine database and master CSV drug dataset to correct OCR typos
and link extracted names to known drugs.
"""

import csv
import logging
import os
from rapidfuzz import fuzz, process
import psycopg2

from app.config import settings

logger = logging.getLogger(__name__)

# Fallback dataset path
DATA_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "drugs_dataset.csv")

# Known Brand Name -> Generic Mapping for Rx dataset coverage
BRAND_GENERIC_MAP = {
    "azimax": ("Azithromycin", "Azimax"),
    "toniflex": ("Nefopam", "Toniflex"),
    "nims": ("Nimesulide", "Nims"),
    "dicloran": ("Diclofenac", "Dicloran"),
    "caricef": ("Cefixime", "Caricef"),
    "novidat": ("Ciprofloxacin", "Novidat"),
    "cefiget": ("Cefixime", "Cefiget"),
    "azitma": ("Azithromycin", "Azitma"),
    "provas": ("Valsartan", "Provas"),
    "distalgesic": ("Dextropropoxyphene", "Distalgesic"),
    "atcomid": ("Atorvastatin", "Atcomid"),
    "atconate": ("Risedronate", "Atconate"),
    "mesulid": ("Nimesulide", "Mesulid"),
    "movelate": ("Mucopolysaccharide", "Movelate"),
    "uriguard": ("Flavoxate", "Uriguard"),
    "pronaz": ("Lansoprazole", "Pronaz"),
    "movax": ("Tizanidine", "Movax"),
    "himox": ("Amoxicillin", "Himox"),
    "ethmiox": ("Amoxicillin", "Himox"),
    "augmentin": ("Amoxicillin and Clavulanic Acid", "Augmentin"),
    "enzoflam": ("Paracetamol + Diclofenac + Serratiopeptidase", "Enzoflam"),
    "pand": ("Pantoprazole + Domperidone", "Pan-D"),
    "pan-d": ("Pantoprazole + Domperidone", "Pan-D"),
    "hexigel": ("Chlorhexidine Gluconate", "Hexigel"),
    "breaky": ("Breaky", "Breaky"),
    "bisleri": ("Bisleri", "Bisleri"),
}


class MedicineMatcher:
    """Matches extracted medicine names to master database using fuzzy search."""

    def __init__(self):
        self._medicines: list[dict] = []
        self._name_list: list[str] = []

    def load_medicines(self):
        """Load medicine corpus from PostgreSQL DB + fallback CSV dataset."""
        self._medicines = []
        self._name_list = []

        # 1. Load from PostgreSQL DB if available
        try:
            conn = psycopg2.connect(settings.database_url)
            cur = conn.cursor()
            cur.execute(
                "SELECT medicine_id, generic_name, brand_name, category, description, side_effects FROM medicines"
            )
            rows = cur.fetchall()
            for row in rows:
                med = {
                    "medicine_id": row[0],
                    "generic_name": row[1],
                    "brand_name": row[2],
                    "category": row[3],
                    "description": row[4],
                    "side_effects": row[5],
                }
                self._medicines.append(med)
                if row[1]:
                    self._name_list.append(row[1])
                if row[2]:
                    self._name_list.append(row[2])

            cur.close()
            conn.close()
            logger.info("Loaded %d medicines from PostgreSQL database.", len(rows))
        except Exception as e:
            logger.warning("Could not load from PostgreSQL database: %s. Using local CSV dataset.", e)

        # 2. Load from local CSV dataset (500+ medicines)
        if os.path.exists(DATA_FILE):
            try:
                with open(DATA_FILE, "r", encoding="utf-8") as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        drug_name = row.get("drug", "").strip()
                        if drug_name:
                            med = {
                                "medicine_id": len(self._medicines) + 1,
                                "generic_name": drug_name,
                                "brand_name": drug_name,
                                "category": row.get("usage", "General"),
                                "description": row.get("dosage", ""),
                                "side_effects": row.get("side_effects", ""),
                            }
                            self._medicines.append(med)
                            self._name_list.append(drug_name)
                logger.info("Loaded dataset medicines from CSV. Total corpus size: %d names.", len(self._name_list))
            except Exception as e:
                logger.error("Error reading CSV dataset: %s", e)

        # 3. Add brand name corpus mappings
        for b_name, (g_name, b_brand) in BRAND_GENERIC_MAP.items():
            self._name_list.append(b_name)
            self._name_list.append(b_brand)
            self._medicines.append({
                "medicine_id": len(self._medicines) + 1,
                "generic_name": g_name,
                "brand_name": b_brand,
                "category": "Prescription Medication",
                "description": "",
                "side_effects": "",
            })

    def match(self, name: str) -> dict:
        """Find best matching medicine for a given name using RapidFuzz.

        Handles typos:
            "Amoxcillin" -> "Amoxicillin"
            "Panadoi" -> "Panadol"
            "Azimax" -> "Azimax (Azithromycin)"
        """
        if not name or not self._name_list:
            return {
                "matched_generic_name": None,
                "matched_brand_name": None,
                "confidence": 0.0,
            }

        clean_name = name.lower().strip()

        # Check exact brand map first
        if clean_name in BRAND_GENERIC_MAP:
            g_name, b_name = BRAND_GENERIC_MAP[clean_name]
            return {
                "matched_generic_name": g_name,
                "matched_brand_name": b_name,
                "confidence": 100.0,
            }

        # RapidFuzz weighted ratio match (threshold 70.0 for reliable drug database match)
        result = process.extractOne(
            clean_name,
            self._name_list,
            scorer=fuzz.WRatio,
            score_cutoff=70.0,
        )

        if result is None:
            return {
                "matched_generic_name": None,
                "matched_brand_name": None,
                "confidence": 0.0,
            }

        matched_name, score, _ = result

        # Lookup generic/brand details
        matched_lower = matched_name.lower()
        if matched_lower in BRAND_GENERIC_MAP:
            g_name, b_name = BRAND_GENERIC_MAP[matched_lower]
            return {
                "matched_generic_name": g_name,
                "matched_brand_name": b_name,
                "confidence": round(score, 1),
            }

        for med in self._medicines:
            generic = (med.get("generic_name") or "").lower()
            brand = (med.get("brand_name") or "").lower()

            if generic == matched_lower or brand == matched_lower:
                return {
                    "matched_generic_name": med.get("generic_name"),
                    "matched_brand_name": med.get("brand_name"),
                    "confidence": round(score, 1),
                }

        return {
            "matched_generic_name": matched_name.title(),
            "matched_brand_name": matched_name.title(),
            "confidence": round(score, 1),
        }

    @property
    def medicine_count(self) -> int:
        return len(self._medicines)
