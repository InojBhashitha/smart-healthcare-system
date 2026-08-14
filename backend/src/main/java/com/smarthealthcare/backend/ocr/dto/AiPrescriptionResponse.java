package com.smarthealthcare.backend.ocr.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * Response from the Python AI microservice.
 * Maps to the PrescriptionResult Pydantic model (snake_case JSON).
 */
public class AiPrescriptionResponse {

    @JsonProperty("raw_text")
    private String rawText;

    private AiQualityReport quality;

    private List<AiMedicineMatch> medicines;

    @JsonProperty("medicines_found")
    private int medicinesFound;

    public AiPrescriptionResponse() {
    }

    public String getRawText() {
        return rawText;
    }

    public void setRawText(String rawText) {
        this.rawText = rawText;
    }

    public AiQualityReport getQuality() {
        return quality;
    }

    public void setQuality(AiQualityReport quality) {
        this.quality = quality;
    }

    public List<AiMedicineMatch> getMedicines() {
        return medicines;
    }

    public void setMedicines(List<AiMedicineMatch> medicines) {
        this.medicines = medicines;
    }

    public int getMedicinesFound() {
        return medicinesFound;
    }

    public void setMedicinesFound(int medicinesFound) {
        this.medicinesFound = medicinesFound;
    }

    /**
     * Image quality assessment from the AI service.
     */
    public static class AiQualityReport {

        @JsonProperty("is_acceptable")
        private boolean isAcceptable;

        @JsonProperty("blur_score")
        private double blurScore;

        private double brightness;

        private double contrast;

        private List<String> issues;

        public AiQualityReport() {
        }

        public boolean isIsAcceptable() {
            return isAcceptable;
        }

        public void setIsAcceptable(boolean acceptable) {
            isAcceptable = acceptable;
        }

        public double getBlurScore() {
            return blurScore;
        }

        public void setBlurScore(double blurScore) {
            this.blurScore = blurScore;
        }

        public double getBrightness() {
            return brightness;
        }

        public void setBrightness(double brightness) {
            this.brightness = brightness;
        }

        public double getContrast() {
            return contrast;
        }

        public void setContrast(double contrast) {
            this.contrast = contrast;
        }

        public List<String> getIssues() {
            return issues;
        }

        public void setIssues(List<String> issues) {
            this.issues = issues;
        }
    }

    /**
     * Single medicine match result from the AI service.
     */
    public static class AiMedicineMatch {

        private String name;
        private String strength;
        private String instruction;

        @JsonProperty("matched_generic_name")
        private String matchedGenericName;

        @JsonProperty("matched_brand_name")
        private String matchedBrandName;

        private double confidence;

        public AiMedicineMatch() {
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getStrength() {
            return strength;
        }

        public void setStrength(String strength) {
            this.strength = strength;
        }

        public String getInstruction() {
            return instruction;
        }

        public void setInstruction(String instruction) {
            this.instruction = instruction;
        }

        public String getMatchedGenericName() {
            return matchedGenericName;
        }

        public void setMatchedGenericName(String matchedGenericName) {
            this.matchedGenericName = matchedGenericName;
        }

        public String getMatchedBrandName() {
            return matchedBrandName;
        }

        public void setMatchedBrandName(String matchedBrandName) {
            this.matchedBrandName = matchedBrandName;
        }

        public double getConfidence() {
            return confidence;
        }

        public void setConfidence(double confidence) {
            this.confidence = confidence;
        }
    }
}
