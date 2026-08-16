package com.smarthealthcare.web.repository;

import com.smarthealthcare.web.entity.PharmacyStock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PharmacyStockRepository extends JpaRepository<PharmacyStock, Long> {
}
