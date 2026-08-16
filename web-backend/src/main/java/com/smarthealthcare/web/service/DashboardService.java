package com.smarthealthcare.web.service;

import com.smarthealthcare.web.dto.DashboardStatsDto;
import com.smarthealthcare.web.entity.PharmacyStock;
import com.smarthealthcare.web.entity.StockStatus;
import com.smarthealthcare.web.repository.MedicineRepository;
import com.smarthealthcare.web.repository.PharmacyStockRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class DashboardService {

    private final PharmacyStockRepository pharmacyStockRepository;
    private final MedicineRepository medicineRepository;

    public DashboardService(PharmacyStockRepository pharmacyStockRepository, MedicineRepository medicineRepository) {
        this.pharmacyStockRepository = pharmacyStockRepository;
        this.medicineRepository = medicineRepository;
    }

    @Transactional(readOnly = true)
    public DashboardStatsDto getDashboardStats(Long pharmacyId) {
        List<PharmacyStock> stocks = pharmacyStockRepository.findByPharmacyPharmacyId(pharmacyId);
        long totalMedicines = medicineRepository.count();
        long totalStockRecords = stocks.size();

        long available = 0;
        long low = 0;
        long critical = 0;
        long outOfStock = 0;

        for (PharmacyStock stock : stocks) {
            StockStatus status = StockStatus.from(stock.getQuantityAvailable(), stock.getMinSafetyLevel());
            switch (status) {
                case AVAILABLE -> available++;
                case LOW_STOCK -> low++;
                case CRITICAL -> critical++;
                case OUT_OF_STOCK -> outOfStock++;
            }
        }

        return DashboardStatsDto.builder()
                .totalMedicines(totalMedicines)
                .totalStockRecords(totalStockRecords)
                .availableStock(available)
                .lowStock(low)
                .criticalStock(critical)
                .outOfStock(outOfStock)
                .build();
    }
}
