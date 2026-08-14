package com.smarthealthcare.backend.user.repository;

import com.smarthealthcare.backend.user.entity.PatientAllergy;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PatientAllergyRepository extends JpaRepository<PatientAllergy, Long> {

    List<PatientAllergy> findByUserUserId(Long userId);

    boolean existsByUserUserIdAndAllergenNameIgnoreCase(Long userId, String allergenName);
}
