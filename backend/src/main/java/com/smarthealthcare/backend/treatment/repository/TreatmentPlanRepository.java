package com.smarthealthcare.backend.treatment.repository;

import com.smarthealthcare.backend.treatment.entity.TreatmentPlan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TreatmentPlanRepository extends JpaRepository<TreatmentPlan, Long> {

    List<TreatmentPlan> findByUserUserId(Long userId);

    @Query("SELECT tp FROM TreatmentPlan tp WHERE tp.user.userId = :userId AND tp.status = 'ACTIVE'")
    List<TreatmentPlan> findActivePlansByUserId(@Param("userId") Long userId);

    Optional<TreatmentPlan> findByPrescriptionPrescriptionId(Long prescriptionId);
}
