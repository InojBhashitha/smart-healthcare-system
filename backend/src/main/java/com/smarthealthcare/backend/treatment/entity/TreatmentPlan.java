package com.smarthealthcare.backend.treatment.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.user.entity.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "treatment_plans")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TreatmentPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "plan_id")
    private Long planId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private User user;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prescription_id", nullable = false)
    @JsonIgnore
    private Prescription prescription;

    @Column(name = "status", nullable = false)
    private String status; // ACTIVE, COMPLETED, CANCELLED

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @OneToMany(mappedBy = "treatmentPlan", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<DoseSchedule> schedules = new ArrayList<>();
}
