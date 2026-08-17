package com.smarthealthcare.backend.pharmacy.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PharmacySearchResponse {

    private Long pharmacyId;
    private String name;
    private String address;
    private Double latitude;
    private Double longitude;
    private String phone;
    private String operatingHours;
    private Boolean deliveryAvailable;
    private Boolean isVerified;
    private Double distanceKm;
    private String stockStatus; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK
    private int matchedMedicinesCount;
    private List<MedicineStockItem> stockItems = new ArrayList<>();

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class MedicineStockItem {
        private String medicineName;
        private String genericName;
        private int quantityAvailable;
        private String availability; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK
    }
}
