package com.smarthealthcare.backend.user.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "patient_allergies")
@Getter
@Setter
@NoArgsConstructor
public class PatientAllergy {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "allergy_id")
    private Long allergyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "allergen_name", nullable = false)
    private String allergenName;

    private String severity; // SEVERE, MODERATE, MILD

    private String notes;

    public PatientAllergy(User user, String allergenName, String severity, String notes) {
        this.user = user;
        this.allergenName = allergenName;
        this.severity = severity;
        this.notes = notes;
    }
}
