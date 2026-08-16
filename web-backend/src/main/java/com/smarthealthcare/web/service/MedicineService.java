package com.smarthealthcare.web.service;

import com.smarthealthcare.web.entity.Medicine;
import com.smarthealthcare.web.repository.MedicineRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class MedicineService {

    private final MedicineRepository medicineRepository;

    public MedicineService(MedicineRepository medicineRepository) {
        this.medicineRepository = medicineRepository;
    }

    @Transactional(readOnly = true)
    public List<Medicine> getAllMedicines() {
        return medicineRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<Medicine> searchMedicines(String query) {
        if (query == null || query.trim().isEmpty()) {
            return medicineRepository.findAll();
        }
        return medicineRepository.findByGenericNameContainingIgnoreCaseOrBrandNameContainingIgnoreCase(query, query);
    }
}
