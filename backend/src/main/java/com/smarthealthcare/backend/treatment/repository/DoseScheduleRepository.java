package com.smarthealthcare.backend.treatment.repository;

import com.smarthealthcare.backend.treatment.entity.DoseSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DoseScheduleRepository extends JpaRepository<DoseSchedule, Long> {

    @Query("SELECT ds FROM DoseSchedule ds WHERE ds.treatmentPlan.user.userId = :userId AND ds.treatmentPlan.status = 'ACTIVE'")
    List<DoseSchedule> findActiveSchedulesByUserId(@Param("userId") Long userId);
}
