package com.smarthealthcare.backend.user.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "patient_medications")
@Getter
@Setter
@NoArgsConstructor
public class PatientMedication {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "medication_id")
    private Long medicationId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "medicine_name", nullable = false)
    private String medicineName;

    @Column(name = "generic_name")
    private String genericName;

    private String strength;

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    public PatientMedication(User user, String medicineName, String genericName, String strength, LocalDate startDate) {
        this.user = user;
        this.medicineName = medicineName;
        this.genericName = genericName;
        this.strength = strength;
        this.startDate = startDate != null ? startDate : LocalDate.now();
        this.isActive = true;
    }
}
