"""RapidFuzz medicine name matcher.

Fuzzy-matches OCR-recognized medicine names against the PostgreSQL
master medicine database to correct OCR typos and link to known drugs.
"""

import logging
from rapidfuzz import fuzz, process
import psycopg2

from app.config import settings

logger = logging.getLogger(__name__)


class MedicineMatcher:
    """Matches extracted medicine names to the database using fuzzy search."""

    def __init__(self):
        self._medicines: list[dict] = []
        self._name_list: list[str] = []

    def load_medicines(self):
        """Load the medicine master list from PostgreSQL.

        Fetches all generic and brand names to build the
        fuzzy matching corpus. Called on startup and can be
        refreshed via the /api/ai/refresh-medicines endpoint.
        """
        try:
            conn = psycopg2.connect(settings.database_url)
            cur = conn.cursor()

            cur.execute(
                "SELECT medicine_id, generic_name, brand_name, "
                "category, description, side_effects "
                "FROM medicines"
            )

            rows = cur.fetchall()
            self._medicines = []
            self._name_list = []

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

                # Add both names to the searchable list
                if row[1]:  # generic_name
                    self._name_list.append(row[1])
                if row[2]:  # brand_name
                    self._name_list.append(row[2])

            cur.close()
            conn.close()

            logger.info(
                "Loaded %d medicines (%d searchable names)",
                len(self._medicines),
                len(self._name_list),
            )

        except Exception as e:
            logger.error("Failed to load medicines from DB: %s", e)
            self._medicines = []
            self._name_list = []

    def match(self, name: str) -> dict:
        """Find the best matching medicine for a given name.

        Uses RapidFuzz weighted ratio scoring to handle OCR typos
        like "Panadoi" → "Panadol", "Amoxicilin" → "Amoxicillin".

        Args:
            name: Medicine name from OCR (possibly misspelled).

        Returns:
            Dict with matched_generic_name, matched_brand_name,
            and confidence score (0-100). Returns empty match
            if no result exceeds the threshold.
        """
        if not self._name_list:
            return {
                "matched_generic_name": None,
                "matched_brand_name": None,
                "confidence": 0.0,
            }

        # Use RapidFuzz process.extractOne for best match
        result = process.extractOne(
            name,
            self._name_list,
            scorer=fuzz.WRatio,
            score_cutoff=settings.fuzzy_match_threshold,
        )

        if result is None:
            return {
                "matched_generic_name": None,
                "matched_brand_name": None,
                "confidence": 0.0,
            }

        matched_name, score, _ = result

        # Find which medicine this name belongs to
        for med in self._medicines:
            generic = med.get("generic_name", "") or ""
            brand = med.get("brand_name", "") or ""

            if (generic.lower() == matched_name.lower()
                    or brand.lower() == matched_name.lower()):
                return {
                    "matched_generic_name": med["generic_name"],
                    "matched_brand_name": med["brand_name"],
                    "confidence": round(score, 1),
                }

        return {
            "matched_generic_name": None,
            "matched_brand_name": None,
            "confidence": 0.0,
        }

    @property
    def medicine_count(self) -> int:
        return len(self._medicines)
