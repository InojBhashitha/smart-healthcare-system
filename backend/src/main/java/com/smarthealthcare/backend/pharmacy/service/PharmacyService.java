package com.smarthealthcare.backend.pharmacy.service;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.pharmacy.dto.PharmacySearchResponse;
import com.smarthealthcare.backend.pharmacy.dto.ReservationRequest;
import com.smarthealthcare.backend.pharmacy.entity.Pharmacy;
import com.smarthealthcare.backend.pharmacy.entity.PharmacyStock;
import com.smarthealthcare.backend.pharmacy.entity.PrescriptionReservation;
import com.smarthealthcare.backend.pharmacy.repository.PharmacyRepository;
import com.smarthealthcare.backend.pharmacy.repository.PharmacyStockRepository;
import com.smarthealthcare.backend.pharmacy.repository.PrescriptionReservationRepository;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.prescription.repository.PrescriptionRepository;
import com.smarthealthcare.backend.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Slf4j
@Service
public class PharmacyService {

    private final PharmacyRepository pharmacyRepository;
    private final PharmacyStockRepository stockRepository;
    private final PrescriptionReservationRepository reservationRepository;
    private final PrescriptionRepository prescriptionRepository;
    private final com.smarthealthcare.backend.treatment.repository.DoseScheduleRepository doseScheduleRepository;
    private final HaversineDistanceCalculator distanceCalculator;

    public PharmacyService(
            PharmacyRepository pharmacyRepository,
            PharmacyStockRepository stockRepository,
            PrescriptionReservationRepository reservationRepository,
            PrescriptionRepository prescriptionRepository,
            com.smarthealthcare.backend.treatment.repository.DoseScheduleRepository doseScheduleRepository,
            HaversineDistanceCalculator distanceCalculator) {

        this.pharmacyRepository = pharmacyRepository;
        this.stockRepository = stockRepository;
        this.reservationRepository = reservationRepository;
        this.prescriptionRepository = prescriptionRepository;
        this.doseScheduleRepository = doseScheduleRepository;
        this.distanceCalculator = distanceCalculator;
    }

    public List<PharmacySearchResponse> searchNearbyPharmacies(
            double userLat,
            double userLng,
            Long userId,
            Long prescriptionId) {

        List<Pharmacy> pharmacies = pharmacyRepository.findByIsVerifiedTrue();

        // 1. Gather distinct medicines from patient's active treatment plan
        Set<String> activeMedNames = new LinkedHashSet<>();
        if (userId != null) {
            var activeSchedules = doseScheduleRepository.findActiveSchedulesByUserId(userId);
            for (var schedule : activeSchedules) {
                if (schedule.getMedicineName() != null && !schedule.getMedicineName().isBlank()) {
                    activeMedNames.add(schedule.getMedicineName().trim());
                }
            }
        }

        // 2. If no active plan, gather from prescription
        if (activeMedNames.isEmpty()) {
            Prescription rx = null;
            if (prescriptionId != null) {
                rx = prescriptionRepository.findWithMedicinesByPrescriptionId(prescriptionId).orElse(null);
            } else if (userId != null) {
                var rxs = prescriptionRepository.findByUserUserIdOrderByUploadedAtDesc(userId);
                if (!rxs.isEmpty()) {
                    rx = prescriptionRepository.findWithMedicinesByPrescriptionId(rxs.get(0).getPrescriptionId()).orElse(null);
                }
            }

            if (rx != null && rx.getMedicines() != null) {
                for (PrescriptionMedicine med : rx.getMedicines()) {
                    String name = med.getMedicine() != null && med.getMedicine().getGenericName() != null
                            ? med.getMedicine().getGenericName()
                            : med.getMedicineName();
                    if (name != null && !name.isBlank()) {
                        activeMedNames.add(name.trim());
                    }
                }
            }
        }

        List<PharmacySearchResponse> result = new ArrayList<>();

        for (Pharmacy p : pharmacies) {
            double distance = distanceCalculator.calculateDistanceKm(userLat, userLng, p.getLatitude(), p.getLongitude());

            PharmacySearchResponse response = new PharmacySearchResponse();
            response.setPharmacyId(p.getPharmacyId());
            response.setName(p.getName());
            response.setAddress(p.getAddress());
            response.setLatitude(p.getLatitude());
            response.setLongitude(p.getLongitude());
            response.setPhone(p.getPhone());
            response.setOperatingHours(p.getOperatingHours());
            response.setDeliveryAvailable(p.getDeliveryAvailable() != null ? p.getDeliveryAvailable() : false);
            response.setIsVerified(p.getIsVerified());
            response.setDistanceKm(distance);

            if (!activeMedNames.isEmpty()) {
                evaluateStockForMedicineNames(response, p.getPharmacyId(), activeMedNames);
            } else {
                // Populate all available stock for this pharmacy from DB
                List<PharmacyStock> allStocks = stockRepository.findByPharmacyPharmacyId(p.getPharmacyId());
                for (PharmacyStock ps : allStocks) {
                    PharmacySearchResponse.MedicineStockItem item = new PharmacySearchResponse.MedicineStockItem();
                    item.setMedicineName(ps.getMedicine().getGenericName());
                    item.setGenericName(ps.getMedicine().getGenericName());
                    item.setQuantityAvailable(ps.getQuantityAvailable());
                    item.setUnitPrice(ps.getUnitPrice());
                    item.setAvailability(ps.getQuantityAvailable() > 20 ? "IN_STOCK" : (ps.getQuantityAvailable() > 0 ? "LOW_STOCK" : "OUT_OF_STOCK"));
                    response.getStockItems().add(item);
                }
                response.setStockStatus("IN_STOCK");
                response.setMatchedMedicinesCount(allStocks.size());
            }

            result.add(response);
        }

        // Sort by distance (nearest first)
        result.sort(Comparator.comparing(PharmacySearchResponse::getDistanceKm));

        return result;
    }

    private void evaluateStockForMedicineNames(
            PharmacySearchResponse response,
            Long pharmacyId,
            Set<String> medicineNames) {

        int inStockCount = 0;
        int lowStockCount = 0;
        int outOfStockCount = 0;

        for (String rawName : medicineNames) {
            String cleanName = rawName.split(" ")[0].trim();

            List<PharmacyStock> stocks = stockRepository
                    .findStockByPharmacyAndMedicineName(pharmacyId, cleanName);

            PharmacySearchResponse.MedicineStockItem item = new PharmacySearchResponse.MedicineStockItem();
            item.setMedicineName(rawName);

            if (!stocks.isEmpty()) {
                PharmacyStock stock = stocks.get(0);
                int qty = stock.getQuantityAvailable();
                item.setQuantityAvailable(qty);
                item.setGenericName(stock.getMedicine().getGenericName());
                item.setUnitPrice(stock.getUnitPrice());

                if (qty <= 0) {
                    item.setAvailability("OUT_OF_STOCK");
                    outOfStockCount++;
                } else if (qty < 20) {
                    item.setAvailability("LOW_STOCK");
                    lowStockCount++;
                } else {
                    item.setAvailability("IN_STOCK");
                    inStockCount++;
                }
            } else {
                item.setQuantityAvailable(0);
                item.setUnitPrice(BigDecimal.ZERO);
                item.setAvailability("OUT_OF_STOCK");
                outOfStockCount++;
            }

            response.getStockItems().add(item);
        }

        response.setMatchedMedicinesCount(medicineNames.size());

        if (outOfStockCount > 0 && inStockCount == 0) {
            response.setStockStatus("OUT_OF_STOCK");
        } else if (outOfStockCount > 0 || lowStockCount > 0) {
            response.setStockStatus("LOW_STOCK");
        } else {
            response.setStockStatus("IN_STOCK");
        }
    }

    @Transactional
    public PrescriptionReservation createReservation(User user, ReservationRequest request) {
        Prescription rx = prescriptionRepository.findById(request.getPrescriptionId())
                .orElseThrow(() -> new ResourceNotFoundException("Prescription not found: " + request.getPrescriptionId()));

        Pharmacy pharmacy = pharmacyRepository.findById(request.getPharmacyId())
                .orElseThrow(() -> new ResourceNotFoundException("Pharmacy not found: " + request.getPharmacyId()));

        String code = "RX-RES-" + (1000 + new Random().nextInt(9000));

        PrescriptionReservation reservation = new PrescriptionReservation();
        reservation.setUser(user);
        reservation.setPrescription(rx);
        reservation.setPharmacy(pharmacy);
        reservation.setStatus("CONFIRMED");
        reservation.setPickupCode(code);
        reservation.setReservedAt(LocalDateTime.now());

        PrescriptionReservation saved = reservationRepository.save(reservation);
        log.info("Created Reservation #{} (Code: {}) for User #{} at {}",
                saved.getReservationId(), code, user.getUserId(), pharmacy.getName());

        return saved;
    }

    public List<PrescriptionReservation> getUserReservations(Long userId) {
        return reservationRepository.findByUserUserIdOrderByReservedAtDesc(userId);
    }
}
