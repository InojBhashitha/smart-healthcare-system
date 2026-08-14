package com.smarthealthcare.backend.treatment.repository;

import com.smarthealthcare.backend.treatment.entity.DoseLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DoseLogRepository extends JpaRepository<DoseLog, Long> {

    Optional<DoseLog> findByDoseScheduleScheduleIdAndLogDate(Long scheduleId, LocalDate logDate);

    @Query("SELECT dl FROM DoseLog dl WHERE dl.doseSchedule.treatmentPlan.user.userId = :userId AND dl.logDate BETWEEN :startDate AND :endDate")
    List<DoseLog> findLogsByUserAndDateRange(
            @Param("userId") Long userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
