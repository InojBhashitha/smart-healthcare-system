package com.smarthealthcare.backend.pharmacy.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ReservationRequest {
    private Long prescriptionId;
    private Long pharmacyId;
}
