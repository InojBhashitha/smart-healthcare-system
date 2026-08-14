package com.smarthealthcare.backend.cdss.dto;

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
public class CdssSafetyResponse {

    private String safetyStatus; // SAFE, WARNING, CRITICAL
    private int totalAlertsCount;
    private List<AllergyAlert> allergyAlerts = new ArrayList<>();
    private List<InteractionWarning> interactionWarnings = new ArrayList<>();
    private List<DuplicateFlag> duplicateFlags = new ArrayList<>();

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class AllergyAlert {
        private String medicineName;
        private String matchedAllergen;
        private String severity;
        private String message;
    }

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class InteractionWarning {
        private String medicine1;
        private String medicine2;
        private String description;
        private boolean isWithCurrentMedication;
    }

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class DuplicateFlag {
        private String medicine1;
        private String medicine2;
        private String sharedIngredient;
        private String message;
    }
}
