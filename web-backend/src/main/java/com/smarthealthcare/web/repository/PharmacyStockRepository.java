package com.smarthealthcare.web.repository;

import com.smarthealthcare.web.entity.PharmacyStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import com.smarthealthcare.web.entity.Pharmacy;
import com.smarthealthcare.web.entity.Medicine;

@Repository
public interface PharmacyStockRepository extends JpaRepository<PharmacyStock, Long> {
    List<PharmacyStock> findByPharmacyPharmacyId(Long pharmacyId);
    List<PharmacyStock> findByMedicineMedicineId(Integer medicineId);
    List<PharmacyStock> findByPharmacy(Pharmacy pharmacy);
    List<PharmacyStock> findByMedicine(Medicine medicine);
}
