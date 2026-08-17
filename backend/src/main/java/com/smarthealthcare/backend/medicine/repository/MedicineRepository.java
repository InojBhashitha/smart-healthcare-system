package com.smarthealthcare.backend.medicine.repository;

import com.smarthealthcare.backend.medicine.entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MedicineRepository extends JpaRepository<Medicine, Integer> {

    List<Medicine> findByGenericNameIgnoreCase(String genericName);

    List<Medicine> findByBrandNameIgnoreCase(String brandName);

}