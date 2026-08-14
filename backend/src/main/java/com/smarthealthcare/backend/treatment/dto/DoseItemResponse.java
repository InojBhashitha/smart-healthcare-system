package com.smarthealthcare.backend.treatment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalTime;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class DoseItemResponse {

    private Long scheduleId;
    private Long planId;
    private String medicineName;
    private String strength;
    private String instruction;
    private String doseSlot; // MORNING, AFTERNOON, EVENING, NIGHT
    private LocalTime scheduledTime;
    private String status; // TAKEN, PENDING, SKIPPED
    private String takenAt;
}
