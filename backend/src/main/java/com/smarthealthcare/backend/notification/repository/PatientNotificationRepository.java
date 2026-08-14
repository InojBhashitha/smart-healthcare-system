package com.smarthealthcare.backend.notification.repository;

import com.smarthealthcare.backend.notification.entity.PatientNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PatientNotificationRepository extends JpaRepository<PatientNotification, Long> {

    List<PatientNotification> findByUserUserIdOrderByCreatedAtDesc(Long userId);

    long countByUserUserIdAndIsReadFalse(Long userId);
}
