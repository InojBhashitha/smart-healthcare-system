package com.smarthealthcare.backend.treatment.service;

import com.smarthealthcare.backend.treatment.entity.DoseSchedule;
import com.smarthealthcare.backend.treatment.entity.TreatmentPlan;
import org.springframework.stereotype.Component;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Component
public class InstructionSchedulerParser {

    /**
     * Parses instruction text and returns a list of DoseSchedule instances for a medicine.
     */
    public List<DoseSchedule> createSchedulesForMedicine(
            TreatmentPlan plan,
            String medName,
            String strength,
            String instruction) {

        List<DoseSchedule> result = new ArrayList<>();
        String text = instruction != null ? instruction.toLowerCase() : "";

        if (text.contains("four times") || text.contains("qds") || text.contains("qid") || text.contains("4 times") || text.contains("4x")) {
            result.add(createSchedule(plan, medName, strength, instruction, "MORNING", LocalTime.of(8, 0)));
            result.add(createSchedule(plan, medName, strength, instruction, "AFTERNOON", LocalTime.of(13, 0)));
            result.add(createSchedule(plan, medName, strength, instruction, "EVENING", LocalTime.of(18, 0)));
            result.add(createSchedule(plan, medName, strength, instruction, "NIGHT", LocalTime.of(22, 0)));
        } else if (text.contains("three times") || text.contains("tds") || text.contains("tid") || text.contains("3 times") || text.contains("3x")) {
            result.add(createSchedule(plan, medName, strength, instruction, "MORNING", LocalTime.of(8, 0)));
            result.add(createSchedule(plan, medName, strength, instruction, "AFTERNOON", LocalTime.of(14, 0)));
            result.add(createSchedule(plan, medName, strength, instruction, "EVENING", LocalTime.of(20, 0)));
        } else if (text.contains("twice") || text.contains("bd") || text.contains("bid") || text.contains("2 times") || text.contains("2x") || text.contains("every 12 hours")) {
            result.add(createSchedule(plan, medName, strength, instruction, "MORNING", LocalTime.of(8, 0)));
            result.add(createSchedule(plan, medName, strength, instruction, "EVENING", LocalTime.of(20, 0)));
        } else if (text.contains("night") || text.contains("bedtime") || text.contains("hs")) {
            result.add(createSchedule(plan, medName, strength, instruction, "NIGHT", LocalTime.of(22, 0)));
        } else if (text.contains("afternoon") || text.contains("noon")) {
            result.add(createSchedule(plan, medName, strength, instruction, "AFTERNOON", LocalTime.of(14, 0)));
        } else if (text.contains("evening")) {
            result.add(createSchedule(plan, medName, strength, instruction, "EVENING", LocalTime.of(20, 0)));
        } else {
            // Default to once daily MORNING (8:00 AM)
            result.add(createSchedule(plan, medName, strength, instruction, "MORNING", LocalTime.of(8, 0)));
        }

        return result;
    }

    private DoseSchedule createSchedule(
            TreatmentPlan plan,
            String medName,
            String strength,
            String instruction,
            String slot,
            LocalTime time) {

        DoseSchedule schedule = new DoseSchedule();
        schedule.setTreatmentPlan(plan);
        schedule.setMedicineName(medName);
        schedule.setStrength(strength);
        schedule.setInstruction(instruction);
        schedule.setDoseSlot(slot);
        schedule.setScheduledTime(time);
        return schedule;
    }
}
