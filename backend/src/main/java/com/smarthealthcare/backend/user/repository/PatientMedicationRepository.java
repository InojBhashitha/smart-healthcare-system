package com.smarthealthcare.backend.user.repository;

import com.smarthealthcare.backend.user.entity.PatientMedication;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PatientMedicationRepository extends JpaRepository<PatientMedication, Long> {

    List<PatientMedication> findByUserUserIdAndIsActiveTrue(Long userId);

    List<PatientMedication> findByUserUserId(Long userId);
}
