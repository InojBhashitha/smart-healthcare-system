package com.smarthealthcare.backend.ocr.dto;

public class MedicineInfo {

    private String name;
    private String strength;
    private String instruction;
    private double confidence;
    private String matchedGenericName;
    private String matchedBrandName;

    public MedicineInfo() {
    }

    public MedicineInfo(String name, String strength, String instruction) {
        this.name = name;
        this.strength = strength;
        this.instruction = instruction;
        this.confidence = 0.0;
    }

    public MedicineInfo(String name, String strength, String instruction, double confidence) {
        this.name = name;
        this.strength = strength;
        this.instruction = instruction;
        this.confidence = confidence;
    }

    public MedicineInfo(String name, String strength, String instruction, double confidence, String matchedGenericName, String matchedBrandName) {
        this.name = name;
        this.strength = strength;
        this.instruction = instruction;
        this.confidence = confidence;
        this.matchedGenericName = matchedGenericName;
        this.matchedBrandName = matchedBrandName;
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

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
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
}