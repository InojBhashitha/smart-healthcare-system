package com.smarthealthcare.backend.pharmacy.repository;

import com.smarthealthcare.backend.pharmacy.entity.PrescriptionReservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PrescriptionReservationRepository extends JpaRepository<PrescriptionReservation, Long> {

    List<PrescriptionReservation> findByUserUserIdOrderByReservedAtDesc(Long userId);

    List<PrescriptionReservation> findByPharmacyPharmacyIdOrderByReservedAtDesc(Long pharmacyId);
}
