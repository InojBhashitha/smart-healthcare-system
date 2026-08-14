package com.smarthealthcare.backend.pharmacy.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.user.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "prescription_reservations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PrescriptionReservation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "reservation_id")
    private Long reservationId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "prescription_id", nullable = false)
    @JsonIgnoreProperties({"user", "medicines", "extractedText"})
    private Prescription prescription;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "pharmacy_id", nullable = false)
    private Pharmacy pharmacy;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnoreProperties({"password", "enabled", "role"})
    private User user;

    @Column(name = "status", nullable = false)
    private String status; // PENDING, CONFIRMED, READY_FOR_PICKUP, COMPLETED, CANCELLED

    @Column(name = "pickup_code", nullable = false, unique = true)
    private String pickupCode;

    @Column(name = "reserved_at", nullable = false)
    private LocalDateTime reservedAt;
}
