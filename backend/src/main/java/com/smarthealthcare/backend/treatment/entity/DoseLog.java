package com.smarthealthcare.backend.treatment.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "dose_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DoseLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "log_id")
    private Long logId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "schedule_id", nullable = false)
    private DoseSchedule doseSchedule;

    @Column(name = "log_date", nullable = false)
    private LocalDate logDate;

    @Column(name = "status", nullable = false)
    private String status; // TAKEN, SKIPPED, MISSED

    @Column(name = "taken_at")
    private LocalDateTime takenAt;
}
