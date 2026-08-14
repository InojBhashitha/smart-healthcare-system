package com.smarthealthcare.backend.config;

import com.smarthealthcare.backend.medicine.entity.Medicine;
import com.smarthealthcare.backend.medicine.repository.MedicineRepository;
import com.smarthealthcare.backend.pharmacy.entity.Pharmacy;
import com.smarthealthcare.backend.pharmacy.entity.PharmacyStock;
import com.smarthealthcare.backend.pharmacy.repository.PharmacyRepository;
import com.smarthealthcare.backend.pharmacy.repository.PharmacyStockRepository;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@Component
public class PharmacyDataSeeder {

    private final PharmacyRepository pharmacyRepository;
    private final PharmacyStockRepository stockRepository;
    private final MedicineRepository medicineRepository;

    public PharmacyDataSeeder(
            PharmacyRepository pharmacyRepository,
            PharmacyStockRepository stockRepository,
            MedicineRepository medicineRepository) {

        this.pharmacyRepository = pharmacyRepository;
        this.stockRepository = stockRepository;
        this.medicineRepository = medicineRepository;
    }

    @PostConstruct
    public void seedPharmacyData() {
        if (pharmacyRepository.count() > 0 && stockRepository.count() > 0) {
            log.info("Partner pharmacies and stock already seeded in PostgreSQL.");
            return;
        }

        log.info("Seeding realistic demo partner pharmacies and inventory stock...");

        List<Pharmacy> pharmacies = pharmacyRepository.findAll();
        Pharmacy p1, p2, p3, p4;

        if (pharmacies.isEmpty()) {
            p1 = createPharmacy("Union Chemists", "24 Galle Road, Colombo 03", 6.9147, 79.8540, "+94 11 234 5678", "8:00 AM - 10:00 PM");
            p2 = createPharmacy("City Health Pharmacy", "56 Station Road, Bambalapitiya", 6.8920, 79.8570, "+94 11 456 7890", "24 Hours");
            p3 = createPharmacy("Lanka Organics Pharmacy", "182 High Level Road, Nugegoda", 6.8712, 79.8860, "+94 11 987 6543", "8:30 AM - 9:00 PM");
            p4 = createPharmacy("Medicare Central Pharmacy", "10 Station Road, Dehiwala", 6.8510, 79.8640, "+94 11 333 4444", "8:00 AM - 11:00 PM");
        } else {
            p1 = pharmacies.get(0);
            p2 = pharmacies.size() > 1 ? pharmacies.get(1) : p1;
            p3 = pharmacies.size() > 2 ? pharmacies.get(2) : p1;
            p4 = pharmacies.size() > 3 ? pharmacies.get(3) : p1;
        }

        List<Medicine> medicines = medicineRepository.findAll();

        for (Medicine med : medicines) {
            String name = med.getGenericName() != null ? med.getGenericName().toLowerCase() : "";

            // Union Chemists: Full stock
            createStock(p1, med, new BigDecimal("45.00"), 300);

            // City Health: Out of stock demo for Amoxicillin
            if (name.contains("amoxicillin")) {
                createStock(p2, med, new BigDecimal("50.00"), 0); // Out of Stock
            } else {
                createStock(p2, med, new BigDecimal("48.00"), 250);
            }

            // Lanka Organics: Low stock demo for Paracetamol
            if (name.contains("paracetamol") || name.contains("panadol")) {
                createStock(p3, med, new BigDecimal("42.00"), 8); // Low Stock
            } else {
                createStock(p3, med, new BigDecimal("44.00"), 180);
            }

            // Medicare Central: Full stock
            createStock(p4, med, new BigDecimal("46.00"), 400);
        }

        log.info("Successfully seeded 4 partner pharmacies with full inventory stock!");
    }

    private Pharmacy createPharmacy(String name, String address, double lat, double lng, String phone, String hours) {
        Pharmacy p = new Pharmacy();
        p.setName(name);
        p.setAddress(address);
        p.setLatitude(lat);
        p.setLongitude(lng);
        p.setPhone(phone);
        p.setOperatingHours(hours);
        p.setIsVerified(true);
        return pharmacyRepository.save(p);
    }

    private void createStock(Pharmacy pharmacy, Medicine medicine, BigDecimal price, int qty) {
        PharmacyStock stock = new PharmacyStock();
        stock.setPharmacy(pharmacy);
        stock.setMedicine(medicine);
        stock.setUnitPrice(price);
        stock.setQuantityAvailable(qty);
        stockRepository.save(stock);
    }
}
