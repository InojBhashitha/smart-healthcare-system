package com.smarthealthcare.backend.prescription.repository;

import com.smarthealthcare.backend.prescription.entity.Prescription;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PrescriptionRepository
        extends JpaRepository<Prescription, Long> {

    @EntityGraph(attributePaths = {
            "medicines",
            "medicines.medicine"
    })
    Optional<Prescription> findWithMedicinesByPrescriptionId(Long prescriptionId);

    List<Prescription> findByUserUserIdOrderByUploadedAtDesc(Long userId);
}