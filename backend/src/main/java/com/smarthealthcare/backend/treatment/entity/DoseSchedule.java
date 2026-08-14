package com.smarthealthcare.backend.treatment.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalTime;

@Entity
@Table(name = "dose_schedules")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DoseSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "schedule_id")
    private Long scheduleId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id", nullable = false)
    @JsonIgnore
    private TreatmentPlan treatmentPlan;

    @Column(name = "medicine_name", nullable = false)
    private String medicineName;

    @Column(name = "strength")
    private String strength;

    @Column(name = "instruction")
    private String instruction;

    @Column(name = "dose_slot", nullable = false)
    private String doseSlot; // MORNING, AFTERNOON, EVENING, NIGHT

    @Column(name = "scheduled_time", nullable = false)
    private LocalTime scheduledTime;
}
