package com.smarthealthcare.backend.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PatientProfileResponse {

    private Long userId;
    private String name;
    private String email;
    private List<AllergyDto> allergies;
    private List<MedicationDto> activeMedications;

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class AllergyDto {
        private Long allergyId;
        private String allergenName;
        private String severity;
        private String notes;
    }

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class MedicationDto {
        private Long medicationId;
        private String medicineName;
        private String genericName;
        private String strength;
        private Boolean isActive;
    }
}
