package com.smarthealthcare.backend.config;

import com.smarthealthcare.backend.medicine.entity.Medicine;
import com.smarthealthcare.backend.medicine.repository.MedicineRepository;
import com.smarthealthcare.backend.pharmacy.entity.Pharmacy;
import com.smarthealthcare.backend.pharmacy.entity.PharmacyStock;
import com.smarthealthcare.backend.pharmacy.repository.PharmacyRepository;
import com.smarthealthcare.backend.pharmacy.repository.PharmacyStockRepository;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.UserRepository;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Slf4j
@Component
public class PharmacyDataSeeder {

    private final PharmacyRepository pharmacyRepository;
    private final PharmacyStockRepository stockRepository;
    private final MedicineRepository medicineRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public PharmacyDataSeeder(
            PharmacyRepository pharmacyRepository,
            PharmacyStockRepository stockRepository,
            MedicineRepository medicineRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder) {

        this.pharmacyRepository = pharmacyRepository;
        this.stockRepository = stockRepository;
        this.medicineRepository = medicineRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @PostConstruct
    public void seedPharmacyData() {
        log.info("Checking and seeding realistic Colombo, Sri Lanka partner pharmacies...");

        // 1. Seed or Update the 3 Main Colombo Pharmacies with Web Dashboards
        Pharmacy p1 = upsertPharmacy("HealthGuard Pharmacy", "Ward Place, Colombo 07", 6.9147, 79.8672, "+94 11 268 7788", "24 Hours", true);
        Pharmacy p2 = upsertPharmacy("Union Chemists", "460 Galle Road, Kollupitiya, Colombo 03", 6.9030, 79.8540, "+94 11 234 5678", "8:00 AM - 10:00 PM", true);
        Pharmacy p3 = upsertPharmacy("State Pharmaceuticals (Rajya Osusala)", "56 Station Road, Bambalapitiya, Colombo 04", 6.8920, 79.8570, "+94 11 456 7890", "24 Hours", true);

        List<Pharmacy> allPharmacies = List.of(p1, p2, p3);

        // De-verify or remove any other pharmacies to ensure only the 3 main dashboard pharmacies appear
        List<Pharmacy> existingPharmacies = pharmacyRepository.findAll();
        for (Pharmacy p : existingPharmacies) {
            if (!p.getName().equalsIgnoreCase(p1.getName()) &&
                !p.getName().equalsIgnoreCase(p2.getName()) &&
                !p.getName().equalsIgnoreCase(p3.getName())) {
                p.setIsVerified(false);
                pharmacyRepository.save(p);
            }
        }
        List<Medicine> medicines = medicineRepository.findAll();

        if (medicines.isEmpty()) {
            log.warn("No medicines found in database to seed stock for.");
            return;
        }

        // 2. Seed stock for each pharmacy if stock count is low
        if (stockRepository.count() < (allPharmacies.size() * 5)) {
            log.info("Seeding inventory stock for {} Colombo partner pharmacies...", allPharmacies.size());
            for (Pharmacy pharmacy : allPharmacies) {
                for (Medicine med : medicines) {
                    if (stockRepository.findByPharmacyPharmacyIdAndMedicineMedicineId(pharmacy.getPharmacyId(), med.getMedicineId()).isEmpty()) {
                        String name = (med.getGenericName() != null ? med.getGenericName() : "").toLowerCase();
                        int qty = 150;
                        BigDecimal price = new BigDecimal("45.00");

                        // Add realistic stock variety
                        if (name.contains("amoxicillin")) {
                            if (pharmacy.getName().contains("Union") || pharmacy.getName().contains("HealthGuard")) {
                                qty = 300; // Full stock
                                price = new BigDecimal("48.00");
                            } else if (pharmacy.getName().contains("Osusala")) {
                                qty = 12; // Low stock
                                price = new BigDecimal("42.00");
                            } else if (pharmacy.getName().contains("Harcourts")) {
                                qty = 0; // Out of stock demo
                                price = new BigDecimal("50.00");
                            }
                        } else if (name.contains("paracetamol") || name.contains("panadol")) {
                            qty = 500;
                            price = new BigDecimal("15.00");
                        } else if (name.contains("azithromycin")) {
                            qty = 80;
                            price = new BigDecimal("120.00");
                        }

                        createStock(pharmacy, med, price, qty);
                    }
                }
            }
        }

        // 3. Seed Pharmacist user accounts for Web Dashboard Login
        seedPharmacistUser("union@pharmacy.lk", "password123", "Union Chemists Manager", p2.getPharmacyId());
        seedPharmacistUser("healthguard@pharmacy.lk", "password123", "HealthGuard Manager", p1.getPharmacyId());
        seedPharmacistUser("osusala@pharmacy.lk", "password123", "Rajya Osusala Pharmacist", p3.getPharmacyId());

        // 4. Seed Patient user accounts for Flutter Mobile App Login
        seedPatientUser("john@example.com", "password123", "John Doe");
        seedPatientUser("test@example.com", "password123", "Test Patient");

        log.info("Successfully seeded all 7 Colombo partner pharmacies, stock, and demo accounts!");
    }

    private Pharmacy upsertPharmacy(String name, String address, double lat, double lng, String phone, String hours, boolean delivery) {
        List<Pharmacy> existing = pharmacyRepository.findAll();
        for (Pharmacy p : existing) {
            if (p.getName().equalsIgnoreCase(name)) {
                p.setAddress(address);
                p.setLatitude(lat);
                p.setLongitude(lng);
                p.setPhone(phone);
                p.setOperatingHours(hours);
                p.setDeliveryAvailable(delivery);
                p.setIsVerified(true);
                return pharmacyRepository.save(p);
            }
        }

        Pharmacy p = new Pharmacy();
        p.setName(name);
        p.setAddress(address);
        p.setLatitude(lat);
        p.setLongitude(lng);
        p.setPhone(phone);
        p.setOperatingHours(hours);
        p.setDeliveryAvailable(delivery);
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

    private void seedPharmacistUser(String email, String rawPassword, String name, Long pharmacyId) {
        Optional<User> existing = userRepository.findByEmail(email);
        if (existing.isEmpty()) {
            User user = new User();
            user.setEmail(email);
            user.setPassword(passwordEncoder.encode(rawPassword));
            user.setName(name);
            user.setRole("PHARMACIST");
            user.setEnabled(true);
            user.setPharmacyId(pharmacyId);
            userRepository.save(user);
            log.info("Created pharmacist web account: {} (Pharmacy ID: {})", email, pharmacyId);
        }
    }

    private void seedPatientUser(String email, String rawPassword, String name) {
        Optional<User> existing = userRepository.findByEmail(email);
        if (existing.isEmpty()) {
            User user = new User();
            user.setEmail(email);
            user.setPassword(passwordEncoder.encode(rawPassword));
            user.setName(name);
            user.setRole("PATIENT");
            user.setEnabled(true);
            userRepository.save(user);
            log.info("Created patient demo account: {}", email);
        }
    }
}
