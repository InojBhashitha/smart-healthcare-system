package com.smarthealthcare.backend.prescription.dto;

public class PrescriptionMedicineResponse {

    private Long id;
    private String medicineName;
    private String strength;
    private String instruction;
    private Boolean verified;
    private Double confidence;

    // Information from the master Medicine table
    private DatabaseMedicineResponse databaseMedicine;

    public PrescriptionMedicineResponse() {
    }

    public PrescriptionMedicineResponse(
            Long id,
            String medicineName,
            String strength,
            String instruction,
            Boolean verified,
            Double confidence,
            DatabaseMedicineResponse databaseMedicine) {

        this.id = id;
        this.medicineName = medicineName;
        this.strength = strength;
        this.instruction = instruction;
        this.verified = verified;
        this.confidence = confidence;
        this.databaseMedicine = databaseMedicine;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getMedicineName() {
        return medicineName;
    }

    public void setMedicineName(String medicineName) {
        this.medicineName = medicineName;
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

    public Boolean getVerified() {
        return verified;
    }

    public void setVerified(Boolean verified) {
        this.verified = verified;
    }

    public Double getConfidence() {
        return confidence;
    }

    public void setConfidence(Double confidence) {
        this.confidence = confidence;
    }

    public DatabaseMedicineResponse getDatabaseMedicine() {
        return databaseMedicine;
    }

    public void setDatabaseMedicine(DatabaseMedicineResponse databaseMedicine) {
        this.databaseMedicine = databaseMedicine;
    }
}