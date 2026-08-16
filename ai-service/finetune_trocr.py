"""Fine-tuning script for Microsoft TrOCR on Doctor Handwriting Recognition Dataset.

Uses a small labeled dataset split:
    - 65 training samples
    - 24 held-out evaluation test set samples (never used during training)

Fine-tunes microsoft/trocr-base-handwritten on doctor prescription handwriting.
Outputs fine-tuned model checkpoint to ai-service/trocr_doctor_finetuned.
"""

import csv
import os
import sys
import torch
from torch.utils.data import Dataset
from PIL import Image
from transformers import (
    TrOCRProcessor,
    VisionEncoderDecoderModel,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
    default_data_collator,
)
import jiwer
import numpy as np

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(os.path.dirname(BASE_DIR), "dataset")
CSV_PATH = os.path.join(DATASET_DIR, "doctor_handwriting_labels.csv")
OUTPUT_DIR = os.path.join(BASE_DIR, "trocr_doctor_finetuned")


class DoctorHandwritingDataset(Dataset):
    def __init__(self, samples, processor, max_target_length=64):
        self.samples = samples
        self.processor = processor
        self.max_target_length = max_target_length

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        sample = self.samples[idx]
        image_path = sample["path"]
        text = sample["label"]

        image = Image.open(image_path).convert("RGB")
        pixel_values = self.processor(image, return_tensors="pt").pixel_values.squeeze(0)

        labels = self.processor.tokenizer(
            text,
            padding="max_length",
            max_length=self.max_target_length,
            truncation=True,
            return_tensors="pt",
        ).input_ids.squeeze(0)

        # Replace padding token id with -100 so it is ignored by loss function
        labels[labels == self.processor.tokenizer.pad_token_id] = -100

        return {
            "pixel_values": pixel_values,
            "labels": labels,
        }


def load_dataset_samples():
    img_dir1 = os.path.join(DATASET_DIR, "img")
    img_dir2 = os.path.join(DATASET_DIR, "img", "img")

    samples = []
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            fn = row["filename"].strip()
            label = row["label"].strip()

            p2 = os.path.join(img_dir2, fn)
            p1 = os.path.join(img_dir1, fn)
            path = p2 if os.path.exists(p2) else (p1 if os.path.exists(p1) else None)

            if path:
                samples.append({"path": path, "label": label})
    return samples


def compute_metrics(pred, processor):
    labels_ids = pred.label_ids
    pred_ids = pred.predictions

    pred_ids[pred_ids == -100] = processor.tokenizer.pad_token_id
    labels_ids[labels_ids == -100] = processor.tokenizer.pad_token_id

    pred_str = processor.batch_decode(pred_ids, skip_special_tokens=True)
    labels_str = processor.batch_decode(labels_ids, skip_special_tokens=True)

    cer_list = []
    for ref, hyp in zip(labels_str, pred_str):
        if ref.strip():
            cer_list.append(jiwer.cer(ref.lower(), hyp.lower()))

    cer = float(np.mean(cer_list)) if cer_list else 1.0
    return {"cer": cer}


def run_finetuning():
    print("=" * 65)
    print("🚀 Fine-Tuning TrOCR on Doctor Handwriting Recognition Dataset")
    print("=" * 65)

    samples = load_dataset_samples()
    print(f"Total dataset samples: {len(samples)}")

    # Split into 65 train samples and 24 held-out test set samples
    train_samples = samples[:65]
    eval_samples = samples[65:]

    print(f"Training set size : {len(train_samples)} samples")
    print(f"Held-out test set : {len(eval_samples)} samples (never used during training)")

    processor = TrOCRProcessor.from_pretrained("microsoft/trocr-base-handwritten")
    model = VisionEncoderDecoderModel.from_pretrained("microsoft/trocr-base-handwritten")

    # Set special tokens
    model.config.decoder_start_token_id = processor.tokenizer.cls_token_id
    model.config.pad_token_id = processor.tokenizer.pad_token_id
    model.config.vocab_size = model.config.decoder.vocab_size

    # Freeze vision encoder parameters to save RAM and speed up training on CPU
    for param in model.encoder.parameters():
        param.requires_grad = False

    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Trainable parameters: {trainable_params:,} (Vision encoder frozen for CPU efficiency)")

    train_dataset = DoctorHandwritingDataset(train_samples, processor)
    eval_dataset = DoctorHandwritingDataset(eval_samples, processor)

    training_args = Seq2SeqTrainingArguments(
        output_dir=OUTPUT_DIR,
        per_device_train_batch_size=1,
        per_device_eval_batch_size=1,
        gradient_accumulation_steps=4,
        fp16=torch.cuda.is_available(),
        predict_with_generate=True,
        num_train_epochs=6,
        logging_steps=5,
        save_strategy="epoch",
        eval_strategy="epoch",
        save_total_limit=1,
        learning_rate=5e-5,
        weight_decay=0.01,
        report_to="none",
        dataloader_num_workers=0,
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=eval_dataset,
        data_collator=default_data_collator,
        compute_metrics=lambda p: compute_metrics(p, processor),
    )

    print("\nStarting fine-tuning...")
    trainer.train()

    print("\nSaving fine-tuned model to:", OUTPUT_DIR)
    model.save_pretrained(OUTPUT_DIR)
    processor.save_pretrained(OUTPUT_DIR)
    print("Fine-tuning complete!")


if __name__ == "__main__":
    run_finetuning()
