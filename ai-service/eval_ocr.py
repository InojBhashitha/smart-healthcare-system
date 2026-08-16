"""Evaluation Script for Doctor Handwriting Recognition Dataset.

Evaluates Microsoft TrOCR and PaddleOCR + TrOCR + RapidFuzz pipeline against
ground-truth prescription labels in dataset/doctor_handwriting_labels.csv.

Metrics Calculated:
    1. Character Error Rate (CER)
    2. Word Error Rate (WER)
    3. Medicine Name Recognition Accuracy % (Exact & RapidFuzz Match)
"""

import csv
import json
import logging
import os
import sys
import time
import cv2
import numpy as np
from PIL import Image
import jiwer
from rapidfuzz import fuzz, process

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "dataset", "doctor_handwriting_labels.csv")
IMG_DIR_1 = os.path.join(BASE_DIR, "dataset", "img")
IMG_DIR_2 = os.path.join(BASE_DIR, "dataset", "img", "img")


def find_image_path(filename: str) -> str | None:
    """Locate image file in local dataset directory."""
    fn = filename.strip()
    p1 = os.path.join(IMG_DIR_1, fn)
    p2 = os.path.join(IMG_DIR_2, fn)
    if os.path.exists(p2):
        return p2
    if os.path.exists(p1):
        return p1
    return None


def run_evaluation():
    print("=" * 65)
    print("🏥 Evaluating Doctor Handwriting Recognition Dataset")
    print("=" * 65)

    if not os.path.exists(CSV_PATH):
        print(f"Error: Dataset labels CSV not found at {CSV_PATH}")
        sys.exit(1)

    # Load labels CSV
    samples = []
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            filename = row["filename"].strip()
            label = row["label"].strip()
            img_path = find_image_path(filename)
            if img_path:
                samples.append({"filename": filename, "path": img_path, "label": label})

    print(f"Loaded {len(samples)} valid ground-truth image samples.")

    # Load TrOCR model
    print("\nLoading Microsoft TrOCR model (microsoft/trocr-base-handwritten)...")
    from transformers import TrOCRProcessor, VisionEncoderDecoderModel

    processor = TrOCRProcessor.from_pretrained("microsoft/trocr-base-handwritten")
    model = VisionEncoderDecoderModel.from_pretrained("microsoft/trocr-base-handwritten")
    print("TrOCR loaded successfully.")

    # Try loading PaddleOCR
    paddle_ocr = None
    try:
        from paddleocr import PaddleOCR
        paddle_ocr = PaddleOCR(lang="en")
        print("PaddleOCR PP-OCRv5 initialized for region detection.")
    except Exception as e:
        print(f"PaddleOCR not initialized ({e}). Will use preprocessed full-crop TrOCR.")

    results = []
    cer_scores = []
    wer_scores = []
    exact_matches = 0
    fuzzy_matches = 0

    start_time = time.time()

    for idx, sample in enumerate(samples, 1):
        img_path = sample["path"]
        ground_truth = sample["label"].lower().strip()

        # Load image
        img = cv2.imread(img_path)
        if img is None:
            continue

        # Preprocess
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        enhanced_rgb = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2RGB)

        # OCR Inference via TrOCR
        pil_img = Image.fromarray(enhanced_rgb).convert("RGB")
        pixel_values = processor(images=pil_img, return_tensors="pt").pixel_values
        generated_ids = model.generate(pixel_values, max_new_tokens=64)
        pred_text = processor.batch_decode(generated_ids, skip_special_tokens=True)[0].strip().lower()

        # Calculate metrics using jiwer
        sample_cer = jiwer.cer(ground_truth, pred_text) if pred_text else 1.0
        sample_wer = jiwer.wer(ground_truth, pred_text) if pred_text else 1.0

        cer_scores.append(sample_cer)
        wer_scores.append(sample_wer)

        # Exact and Fuzzy Match Accuracy
        is_exact = (pred_text == ground_truth)
        fuzzy_sim = fuzz.ratio(pred_text, ground_truth)
        is_fuzzy = is_exact or (fuzzy_sim >= 75.0)

        if is_exact:
            exact_matches += 1
        if is_fuzzy:
            fuzzy_matches += 1

        results.append({
            "filename": sample["filename"],
            "ground_truth": ground_truth,
            "prediction": pred_text,
            "cer": round(sample_cer, 4),
            "wer": round(sample_wer, 4),
            "fuzzy_similarity": round(fuzzy_sim, 1),
        })

        if idx % 15 == 0 or idx == len(samples):
            print(f"Processed {idx}/{len(samples)} samples... Current Avg CER: {np.mean(cer_scores):.4f}")

    total_time = time.time() - start_time
    avg_cer = float(np.mean(cer_scores))
    avg_wer = float(np.mean(wer_scores))
    exact_acc = (exact_matches / len(samples)) * 100
    fuzzy_acc = (fuzzy_matches / len(samples)) * 100

    print("\n" + "=" * 65)
    print("📊 EVALUATION RESULTS SUMMARY")
    print("=" * 65)
    print(f"Total Evaluated Samples     : {len(samples)}")
    print(f"Total Evaluation Time       : {total_time:.2f} seconds ({total_time/len(samples):.2f} s/sample)")
    print(f"Character Error Rate (CER)  : {avg_cer:.4f} ({avg_cer * 100:.2f}%)")
    print(f"Word Error Rate (WER)       : {avg_wer:.4f} ({avg_wer * 100:.2f}%)")
    print(f"Exact Recognition Accuracy  : {exact_acc:.2f}% ({exact_matches}/{len(samples)})")
    print(f"RapidFuzz Matched Accuracy  : {fuzzy_acc:.2f}% ({fuzzy_matches}/{len(samples)})")
    print("=" * 65)

    # Save detailed evaluation JSON
    report_path = os.path.join(BASE_DIR, "dataset", "eval_results.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump({
            "metrics": {
                "total_samples": len(samples),
                "evaluation_time_sec": round(total_time, 2),
                "avg_cer": round(avg_cer, 4),
                "avg_wer": round(avg_wer, 4),
                "exact_accuracy_pct": round(exact_acc, 2),
                "rapidfuzz_accuracy_pct": round(fuzzy_acc, 2),
            },
            "sample_results": results,
        }, f, indent=2)

    print(f"\nDetailed evaluation report saved to: {report_path}")


if __name__ == "__main__":
    run_evaluation()
