package com.smarthealthcare.web.repository;

import com.smarthealthcare.web.entity.Medicine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicineRepository extends JpaRepository<Medicine, Integer> {
    List<Medicine> findByGenericNameContainingIgnoreCaseOrBrandNameContainingIgnoreCase(String genericName, String brandName);
}
