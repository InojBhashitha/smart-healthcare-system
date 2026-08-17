package com.smarthealthcare.web.service;

import com.smarthealthcare.web.entity.PharmacyStock;
import com.smarthealthcare.web.entity.Pharmacy;
import com.smarthealthcare.web.entity.Medicine;
import com.smarthealthcare.web.exception.PharmacyNotFoundException;
import com.smarthealthcare.web.exception.MedicineNotFoundException;
import com.smarthealthcare.web.exception.StockNotFoundException;
import com.smarthealthcare.web.exception.UnauthorizedPharmacyAccessException;
import com.smarthealthcare.web.repository.PharmacyRepository;
import com.smarthealthcare.web.repository.MedicineRepository;
import com.smarthealthcare.web.repository.PharmacyStockRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.smarthealthcare.web.dto.StockDto;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class StockService {

    private final PharmacyStockRepository pharmacyStockRepository;
    private final PharmacyRepository pharmacyRepository;
    private final MedicineRepository medicineRepository;

    public StockService(PharmacyStockRepository pharmacyStockRepository,
                        PharmacyRepository pharmacyRepository,
                        MedicineRepository medicineRepository) {
        this.pharmacyStockRepository = pharmacyStockRepository;
        this.pharmacyRepository = pharmacyRepository;
        this.medicineRepository = medicineRepository;
    }

    @Transactional(readOnly = true)
    public List<PharmacyStock> getStockByPharmacy(Long pharmacyId) {
        return pharmacyStockRepository.findByPharmacyPharmacyId(pharmacyId);
    }

    @Transactional
    public PharmacyStock addStock(Long pharmacyId, Integer medicineId, PharmacyStock stockData) {
        Pharmacy pharmacy = pharmacyRepository.findById(pharmacyId)
                .orElseThrow(() -> new PharmacyNotFoundException("Pharmacy not found: " + pharmacyId));
        Medicine medicine = medicineRepository.findById(medicineId)
                .orElseThrow(() -> new MedicineNotFoundException("Medicine not found: " + medicineId));

        PharmacyStock stock = new PharmacyStock();
        stock.setPharmacy(pharmacy);
        stock.setMedicine(medicine);
        stock.setQuantityAvailable(stockData.getQuantityAvailable() != null ? stockData.getQuantityAvailable() : 0);
        stock.setUnitPrice(stockData.getUnitPrice());
        stock.setMinSafetyLevel(stockData.getMinSafetyLevel() != null ? stockData.getMinSafetyLevel() : 0);
        stock.setUpdatedAt(LocalDateTime.now());

        return pharmacyStockRepository.save(stock);
    }

    @Transactional
    public PharmacyStock updateStock(Long pharmacyId, Long stockId, PharmacyStock stockData) {
        PharmacyStock stock = pharmacyStockRepository.findById(stockId)
                .orElseThrow(() -> new StockNotFoundException("Stock record not found: " + stockId));

        // Enforce pharmacy data isolation
        if (!stock.getPharmacy().getPharmacyId().equals(pharmacyId)) {
            throw new UnauthorizedPharmacyAccessException("Access denied. You cannot modify stock for another pharmacy.");
        }

        if (stockData.getQuantityAvailable() != null) {
            stock.setQuantityAvailable(stockData.getQuantityAvailable());
        }
        if (stockData.getUnitPrice() != null) {
            stock.setUnitPrice(stockData.getUnitPrice());
        }
        if (stockData.getMinSafetyLevel() != null) {
            stock.setMinSafetyLevel(stockData.getMinSafetyLevel());
        }
        stock.setUpdatedAt(LocalDateTime.now());

        return pharmacyStockRepository.save(stock);
    }

    @Transactional
    public void deleteStock(Long pharmacyId, Long stockId) {
        PharmacyStock stock = pharmacyStockRepository.findById(stockId)
                .orElseThrow(() -> new StockNotFoundException("Stock record not found: " + stockId));

        // Enforce pharmacy data isolation
        if (!stock.getPharmacy().getPharmacyId().equals(pharmacyId)) {
            throw new UnauthorizedPharmacyAccessException("Access denied. You cannot delete stock for another pharmacy.");
        }

        pharmacyStockRepository.delete(stock);
    }

    public double calculateSafetyPercentage(Integer quantityAvailable, Integer minSafetyLevel) {
        if (quantityAvailable == null || quantityAvailable <= 0) {
            return 0.0;
        }
        if (minSafetyLevel == null || minSafetyLevel <= 0) {
            return 100.0;
        }
        return (quantityAvailable * 100.0) / minSafetyLevel;
    }

    public StockDto convertToDto(PharmacyStock stock) {
        double safetyPercentage = calculateSafetyPercentage(stock.getQuantityAvailable(), stock.getMinSafetyLevel());
        return StockDto.from(stock, safetyPercentage);
    }
}
