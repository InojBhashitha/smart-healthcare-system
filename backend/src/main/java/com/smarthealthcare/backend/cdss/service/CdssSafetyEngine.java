package com.smarthealthcare.backend.cdss.service;

import com.smarthealthcare.backend.cdss.dto.CdssSafetyResponse;
import com.smarthealthcare.backend.medicine.entity.DrugInteraction;
import com.smarthealthcare.backend.medicine.entity.Medicine;
import com.smarthealthcare.backend.medicine.repository.DrugInteractionRepository;
import com.smarthealthcare.backend.medicine.repository.MedicineRepository;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.user.entity.PatientAllergy;
import com.smarthealthcare.backend.user.entity.PatientMedication;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.PatientAllergyRepository;
import com.smarthealthcare.backend.user.repository.PatientMedicationRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
public class CdssSafetyEngine {

    private final PatientAllergyRepository allergyRepository;
    private final PatientMedicationRepository activeMedRepository;
    private final DrugInteractionRepository interactionRepository;
    private final MedicineRepository medicineRepository;

    public CdssSafetyEngine(
            PatientAllergyRepository allergyRepository,
            PatientMedicationRepository activeMedRepository,
            DrugInteractionRepository interactionRepository,
            MedicineRepository medicineRepository) {

        this.allergyRepository = allergyRepository;
        this.activeMedRepository = activeMedRepository;
        this.interactionRepository = interactionRepository;
        this.medicineRepository = medicineRepository;
    }

    /**
     * Run full Clinical Decision Support System (CDSS) safety analysis.
     *
     * @param prescription the prescription entity with parsed medicines
     * @return CdssSafetyResponse containing alerts, interaction warnings, and duplicate flags
     */
    public CdssSafetyResponse evaluatePrescriptionSafety(Prescription prescription) {
        User user = prescription.getUser();
        List<PrescriptionMedicine> rxMeds = prescription.getMedicines();

        List<PatientAllergy> patientAllergies = user != null
                ? allergyRepository.findByUserUserId(user.getUserId())
                : new ArrayList<>();

        List<PatientMedication> activeMeds = user != null
                ? activeMedRepository.findByUserUserIdAndIsActiveTrue(user.getUserId())
                : new ArrayList<>();

        CdssSafetyResponse response = new CdssSafetyResponse();

        // 1. Allergy Detection Engine
        for (PrescriptionMedicine rxMed : rxMeds) {
            String rxName = rxMed.getMedicineName();
            String genericName = getGenericName(rxMed);

            for (PatientAllergy allergy : patientAllergies) {
                String allergen = allergy.getAllergenName();
                if (matchesAllergen(rxName, genericName, allergen)) {
                    response.getAllergyAlerts().add(new CdssSafetyResponse.AllergyAlert(
                            rxName,
                            allergen,
                            allergy.getSeverity() != null ? allergy.getSeverity() : "HIGH",
                            "Allergy Alert: Patient is allergic to " + allergen + ". Please consult your doctor."
                    ));
                }
            }
        }

        // 2. Drug-Drug Interaction Detection (Prescription Meds vs Active Meds)
        for (PrescriptionMedicine rxMed : rxMeds) {
            String name1 = getGenericOrBrandName(rxMed);

            // A) Check interaction with patient's currently taken active medications
            for (PatientMedication activeMed : activeMeds) {
                String activeName = activeMed.getGenericName() != null ? activeMed.getGenericName() : activeMed.getMedicineName();

                List<DrugInteraction> interactions = interactionRepository.findInteraction(name1, activeName);
                for (DrugInteraction inter : interactions) {
                    response.getInteractionWarnings().add(new CdssSafetyResponse.InteractionWarning(
                            rxMed.getMedicineName(),
                            activeMed.getMedicineName(),
                            inter.getDescription(),
                            true // is with currently taken active medication
                    ));
                }
            }
        }

        // B) Check interactions between medicines within the same new prescription
        for (int i = 0; i < rxMeds.size(); i++) {
            for (int j = i + 1; j < rxMeds.size(); j++) {
                String medA = getGenericOrBrandName(rxMeds.get(i));
                String medB = getGenericOrBrandName(rxMeds.get(j));

                List<DrugInteraction> interactions = interactionRepository.findInteraction(medA, medB);
                for (DrugInteraction inter : interactions) {
                    response.getInteractionWarnings().add(new CdssSafetyResponse.InteractionWarning(
                            rxMeds.get(i).getMedicineName(),
                            rxMeds.get(j).getMedicineName(),
                            inter.getDescription(),
                            false
                    ));
                }
            }
        }

        // 3. Duplicate Active Ingredient Detection
        for (PrescriptionMedicine rxMed : rxMeds) {
            String generic1 = getGenericName(rxMed);
            if (generic1 == null) continue;

            for (PatientMedication activeMed : activeMeds) {
                String generic2 = activeMed.getGenericName();
                if (generic2 != null && generic1.equalsIgnoreCase(generic2)) {
                    response.getDuplicateFlags().add(new CdssSafetyResponse.DuplicateFlag(
                            rxMed.getMedicineName(),
                            activeMed.getMedicineName(),
                            generic1,
                            "Duplicate Active Ingredient: Both " + rxMed.getMedicineName() + " and " + activeMed.getMedicineName() + " contain " + generic1 + "."
                    ));
                }
            }
        }

        // Calculate totals and safety status
        int totalAlerts = response.getAllergyAlerts().size()
                + response.getInteractionWarnings().size()
                + response.getDuplicateFlags().size();

        response.setTotalAlertsCount(totalAlerts);

        if (!response.getAllergyAlerts().isEmpty()) {
            response.setSafetyStatus("CRITICAL");
        } else if (totalAlerts > 0) {
            response.setSafetyStatus("WARNING");
        } else {
            response.setSafetyStatus("SAFE");
        }

        log.info("CDSS Analysis complete for Rx #{} — Status: {}, Total Alerts: {}",
                prescription.getPrescriptionId(), response.getSafetyStatus(), totalAlerts);

        return response;
    }

    private boolean matchesAllergen(String medName, String genericName, String allergen) {
        if (medName != null && medName.toLowerCase().contains(allergen.toLowerCase())) {
            return true;
        }
        if (genericName != null && genericName.toLowerCase().contains(allergen.toLowerCase())) {
            return true;
        }
        return false;
    }

    private String getGenericName(PrescriptionMedicine rxMed) {
        if (rxMed.getMedicine() != null && rxMed.getMedicine().getGenericName() != null) {
            return rxMed.getMedicine().getGenericName();
        }
        // Fallback: DB lookup by brand or generic name
        List<Medicine> meds = medicineRepository.findByBrandNameIgnoreCase(rxMed.getMedicineName());
        if (meds.isEmpty()) {
            meds = medicineRepository.findByGenericNameIgnoreCase(rxMed.getMedicineName());
        }
        return !meds.isEmpty() && meds.get(0).getGenericName() != null ? meds.get(0).getGenericName() : rxMed.getMedicineName();
    }

    private String getGenericOrBrandName(PrescriptionMedicine rxMed) {
        String generic = getGenericName(rxMed);
        return generic != null ? generic : rxMed.getMedicineName();
    }
}
