package com.smarthealthcare.backend.report.service;

import com.lowagie.text.*;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.smarthealthcare.backend.cdss.service.CdssSafetyEngine;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.repository.PrescriptionRepository;
import com.smarthealthcare.backend.treatment.dto.AdherenceAnalyticsResponse;
import com.smarthealthcare.backend.treatment.dto.DoseItemResponse;
import com.smarthealthcare.backend.treatment.service.AdherenceAnalyticsService;
import com.smarthealthcare.backend.treatment.service.TreatmentPlanService;
import com.smarthealthcare.backend.user.entity.PatientAllergy;
import com.smarthealthcare.backend.user.entity.PatientMedication;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.PatientAllergyRepository;
import com.smarthealthcare.backend.user.repository.PatientMedicationRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Slf4j
@Service
public class PdfReportService {

    private final PrescriptionRepository prescriptionRepository;
    private final TreatmentPlanService treatmentPlanService;
    private final AdherenceAnalyticsService analyticsService;
    private final PatientAllergyRepository allergyRepository;
    private final PatientMedicationRepository medicationRepository;

    public PdfReportService(
            PrescriptionRepository prescriptionRepository,
            TreatmentPlanService treatmentPlanService,
            AdherenceAnalyticsService analyticsService,
            PatientAllergyRepository allergyRepository,
            PatientMedicationRepository medicationRepository) {

        this.prescriptionRepository = prescriptionRepository;
        this.treatmentPlanService = treatmentPlanService;
        this.analyticsService = analyticsService;
        this.allergyRepository = allergyRepository;
        this.medicationRepository = medicationRepository;
    }

    public ByteArrayInputStream generateHealthSummaryPdf(User user) {
        Document document = new Document(PageSize.A4, 36, 36, 36, 36);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // Colors
            Color primaryColor = new Color(13, 148, 136); // Teal #0D9488
            Color darkColor = new Color(15, 23, 42); // Dark #0F172A

            // Title
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 20, primaryColor);
            Paragraph title = new Paragraph("Smart Healthcare — Medical Health Summary", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            document.add(title);

            Font subFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.GRAY);
            Paragraph sub = new Paragraph("Generated on: " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")), subFont);
            sub.setAlignment(Element.ALIGN_CENTER);
            document.add(sub);
            document.add(Chunk.NEWLINE);

            // Patient Info Box
            Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, darkColor);
            document.add(new Paragraph("1. Patient Profile Information", headerFont));
            document.add(Chunk.NEWLINE);

            PdfPTable patientTable = new PdfPTable(2);
            patientTable.setWidthPercentage(100);
            patientTable.addCell(new Phrase("Patient Name: " + (user.getName() != null ? user.getName() : "N/A")));
            patientTable.addCell(new Phrase("Email: " + user.getEmail()));
            patientTable.addCell(new Phrase("Role: " + user.getRole()));
            patientTable.addCell(new Phrase("Status: Active Verified Patient"));
            document.add(patientTable);
            document.add(Chunk.NEWLINE);

            // Safety Profile & Drug Allergies
            document.add(new Paragraph("2. Clinical Safety Profile & Allergies", headerFont));
            document.add(Chunk.NEWLINE);

            List<PatientAllergy> allergies = allergyRepository.findByUserUserId(user.getUserId());
            List<PatientMedication> activeMeds = medicationRepository.findByUserUserIdAndIsActiveTrue(user.getUserId());

            PdfPTable safetyTable = new PdfPTable(2);
            safetyTable.setWidthPercentage(100);

            StringBuilder allergyStr = new StringBuilder();
            if (allergies.isEmpty()) {
                allergyStr.append("No known drug allergies reported.");
            } else {
                for (PatientAllergy a : allergies) {
                    allergyStr.append("• ").append(a.getAllergenName()).append(" (").append(a.getSeverity()).append(")\n");
                }
            }
            safetyTable.addCell(new Phrase("Known Drug Allergies:\n" + allergyStr));

            StringBuilder medStr = new StringBuilder();
            if (activeMeds.isEmpty()) {
                medStr.append("No active medications recorded.");
            } else {
                for (PatientMedication m : activeMeds) {
                    medStr.append("• ").append(m.getMedicineName()).append(" ").append(m.getStrength() != null ? m.getStrength() : "").append("\n");
                }
            }
            safetyTable.addCell(new Phrase("Current Active Medications:\n" + medStr));
            document.add(safetyTable);
            document.add(Chunk.NEWLINE);

            // Adherence Score
            AdherenceAnalyticsResponse analytics = analyticsService.calculateAdherence(user.getUserId());
            document.add(new Paragraph("3. Medication Adherence Analytics", headerFont));
            document.add(Chunk.NEWLINE);

            PdfPTable analyticsTable = new PdfPTable(3);
            analyticsTable.setWidthPercentage(100);
            analyticsTable.addCell(new Phrase("7-Day Adherence Score: " + String.format("%.1f%%", analytics.getAdherenceScore())));
            analyticsTable.addCell(new Phrase("Streak Days: " + analytics.getCurrentStreakDays() + " days"));
            analyticsTable.addCell(new Phrase("Taken Doses: " + analytics.getTotalDosesTaken() + " / " + analytics.getTotalDosesScheduled()));
            document.add(analyticsTable);
            document.add(Chunk.NEWLINE);

            // Active Dosage Checklist
            document.add(new Paragraph("4. Today's Scheduled Dosage Plan", headerFont));
            document.add(Chunk.NEWLINE);

            List<DoseItemResponse> todayDoses = treatmentPlanService.getTodayDoseChecklist(user.getUserId());
            PdfPTable doseTable = new PdfPTable(4);
            doseTable.setWidthPercentage(100);
            doseTable.addCell(new Phrase("Medicine Name", headerFont));
            doseTable.addCell(new Phrase("Dose Slot", headerFont));
            doseTable.addCell(new Phrase("Scheduled Time", headerFont));
            doseTable.addCell(new Phrase("Status", headerFont));

            if (todayDoses.isEmpty()) {
                PdfPCell emptyCell = new PdfPCell(new Phrase("No scheduled doses found for today."));
                emptyCell.setColspan(4);
                doseTable.addCell(emptyCell);
            } else {
                for (DoseItemResponse d : todayDoses) {
                    doseTable.addCell(d.getMedicineName() + " (" + (d.getStrength() != null ? d.getStrength() : "") + ")");
                    doseTable.addCell(d.getDoseSlot());
                    doseTable.addCell(d.getScheduledTime() != null ? d.getScheduledTime().toString() : "N/A");
                    doseTable.addCell(d.getStatus());
                }
            }
            document.add(doseTable);

            document.close();
            log.info("Successfully generated PDF Health Summary for User #{}", user.getUserId());

        } catch (Exception e) {
            log.error("Failed to generate PDF report for user #{}: {}", user.getUserId(), e.getMessage());
        }

        return new ByteArrayInputStream(out.toByteArray());
    }
}
