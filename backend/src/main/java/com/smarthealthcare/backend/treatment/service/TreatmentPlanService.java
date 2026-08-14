package com.smarthealthcare.backend.treatment.service;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.prescription.repository.PrescriptionRepository;
import com.smarthealthcare.backend.treatment.dto.DoseItemResponse;
import com.smarthealthcare.backend.treatment.entity.DoseLog;
import com.smarthealthcare.backend.treatment.entity.DoseSchedule;
import com.smarthealthcare.backend.treatment.entity.TreatmentPlan;
import com.smarthealthcare.backend.treatment.repository.DoseLogRepository;
import com.smarthealthcare.backend.treatment.repository.DoseScheduleRepository;
import com.smarthealthcare.backend.treatment.repository.TreatmentPlanRepository;
import com.smarthealthcare.backend.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
public class TreatmentPlanService {

    private final TreatmentPlanRepository planRepository;
    private final DoseScheduleRepository scheduleRepository;
    private final DoseLogRepository logRepository;
    private final PrescriptionRepository prescriptionRepository;
    private final InstructionSchedulerParser parser;

    public TreatmentPlanService(
            TreatmentPlanRepository planRepository,
            DoseScheduleRepository scheduleRepository,
            DoseLogRepository logRepository,
            PrescriptionRepository prescriptionRepository,
            InstructionSchedulerParser parser) {

        this.planRepository = planRepository;
        this.scheduleRepository = scheduleRepository;
        this.logRepository = logRepository;
        this.prescriptionRepository = prescriptionRepository;
        this.parser = parser;
    }

    @Transactional
    public TreatmentPlan generatePlanFromPrescription(Long prescriptionId) {
        Prescription rx = prescriptionRepository.findWithMedicinesByPrescriptionId(prescriptionId)
                .orElseThrow(() -> new ResourceNotFoundException("Prescription not found with ID: " + prescriptionId));

        // Check if plan already exists for this prescription
        Optional<TreatmentPlan> existing = planRepository.findByPrescriptionPrescriptionId(prescriptionId);
        if (existing.isPresent()) {
            return existing.get();
        }

        User user = rx.getUser();
        TreatmentPlan plan = new TreatmentPlan();
        plan.setUser(user);
        plan.setPrescription(rx);
        plan.setStatus("ACTIVE");
        plan.setStartDate(LocalDate.now());
        plan.setEndDate(LocalDate.now().plusDays(30));

        TreatmentPlan savedPlan = planRepository.save(plan);

        // Generate Dose Schedules for each medicine
        List<DoseSchedule> allSchedules = new ArrayList<>();
        for (PrescriptionMedicine rxMed : rx.getMedicines()) {
            List<DoseSchedule> schedules = parser.createSchedulesForMedicine(
                    savedPlan,
                    rxMed.getMedicineName(),
                    rxMed.getStrength(),
                    rxMed.getInstruction()
            );
            allSchedules.addAll(schedules);
        }

        scheduleRepository.saveAll(allSchedules);
        savedPlan.setSchedules(allSchedules);

        log.info("Generated TreatmentPlan #{} with {} schedules for Prescription #{}",
                savedPlan.getPlanId(), allSchedules.size(), prescriptionId);

        return savedPlan;
    }

    public List<DoseItemResponse> getTodayDoseChecklist(Long userId) {
        List<DoseSchedule> activeSchedules = scheduleRepository.findActiveSchedulesByUserId(userId);

        if (activeSchedules.isEmpty()) {
            List<Prescription> userRxs = prescriptionRepository.findByUserUserIdOrderByUploadedAtDesc(userId);
            if (!userRxs.isEmpty()) {
                generatePlanFromPrescription(userRxs.get(0).getPrescriptionId());
                activeSchedules = scheduleRepository.findActiveSchedulesByUserId(userId);
            }
        }

        LocalDate today = LocalDate.now();

        List<DoseItemResponse> checklist = new ArrayList<>();
        for (DoseSchedule ds : activeSchedules) {
            Optional<DoseLog> logOpt = logRepository.findByDoseScheduleScheduleIdAndLogDate(ds.getScheduleId(), today);

            DoseItemResponse dto = new DoseItemResponse();
            dto.setScheduleId(ds.getScheduleId());
            dto.setPlanId(ds.getTreatmentPlan().getPlanId());
            dto.setMedicineName(ds.getMedicineName());
            dto.setStrength(ds.getStrength());
            dto.setInstruction(ds.getInstruction());
            dto.setDoseSlot(ds.getDoseSlot());
            dto.setScheduledTime(ds.getScheduledTime());

            if (logOpt.isPresent()) {
                dto.setStatus(logOpt.get().getStatus());
                dto.setTakenAt(logOpt.get().getTakenAt() != null ? logOpt.get().getTakenAt().toString() : null);
            } else {
                dto.setStatus("PENDING");
                dto.setTakenAt(null);
            }

            checklist.add(dto);
        }

        return checklist;
    }

    @Transactional
    public DoseItemResponse logDoseStatus(Long userId, Long scheduleId, String status) {
        DoseSchedule schedule = scheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new ResourceNotFoundException("Dose schedule not found: " + scheduleId));

        LocalDate today = LocalDate.now();
        DoseLog logEntry = logRepository.findByDoseScheduleScheduleIdAndLogDate(scheduleId, today)
                .orElseGet(() -> {
                    DoseLog newLog = new DoseLog();
                    newLog.setDoseSchedule(schedule);
                    newLog.setLogDate(today);
                    return newLog;
                });

        logEntry.setStatus(status.toUpperCase());
        if ("TAKEN".equalsIgnoreCase(status)) {
            logEntry.setTakenAt(LocalDateTime.now());
        } else {
            logEntry.setTakenAt(null);
        }

        DoseLog savedLog = logRepository.save(logEntry);

        DoseItemResponse dto = new DoseItemResponse();
        dto.setScheduleId(schedule.getScheduleId());
        dto.setPlanId(schedule.getTreatmentPlan().getPlanId());
        dto.setMedicineName(schedule.getMedicineName());
        dto.setStrength(schedule.getStrength());
        dto.setInstruction(schedule.getInstruction());
        dto.setDoseSlot(schedule.getDoseSlot());
        dto.setScheduledTime(schedule.getScheduledTime());
        dto.setStatus(savedLog.getStatus());
        dto.setTakenAt(savedLog.getTakenAt() != null ? savedLog.getTakenAt().toString() : null);

        log.info("Logged dose #{} status to {} for User #{}", scheduleId, status, userId);

        return dto;
    }
}
