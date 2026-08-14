package com.smarthealthcare.backend.pharmacy.repository;

import com.smarthealthcare.backend.pharmacy.entity.PharmacyStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PharmacyStockRepository extends JpaRepository<PharmacyStock, Long> {

    List<PharmacyStock> findByPharmacyPharmacyId(Long pharmacyId);

    @Query("SELECT ps FROM PharmacyStock ps WHERE ps.pharmacy.pharmacyId = :pharmacyId AND (LOWER(ps.medicine.brandName) = LOWER(:medName) OR LOWER(ps.medicine.genericName) = LOWER(:medName))")
    Optional<PharmacyStock> findStockByPharmacyAndMedicineName(
            @Param("pharmacyId") Long pharmacyId,
            @Param("medName") String medName);
}
