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

import java.time.LocalDateTime;
import java.util.*;

@Slf4j
@Service
public class PharmacyService {

    private final PharmacyRepository pharmacyRepository;
    private final PharmacyStockRepository stockRepository;
    private final PrescriptionReservationRepository reservationRepository;
    private final PrescriptionRepository prescriptionRepository;
    private final HaversineDistanceCalculator distanceCalculator;

    public PharmacyService(
            PharmacyRepository pharmacyRepository,
            PharmacyStockRepository stockRepository,
            PrescriptionReservationRepository reservationRepository,
            PrescriptionRepository prescriptionRepository,
            HaversineDistanceCalculator distanceCalculator) {

        this.pharmacyRepository = pharmacyRepository;
        this.stockRepository = stockRepository;
        this.reservationRepository = reservationRepository;
        this.prescriptionRepository = prescriptionRepository;
        this.distanceCalculator = distanceCalculator;
    }

    public List<PharmacySearchResponse> searchNearbyPharmacies(
            double userLat,
            double userLng,
            Long prescriptionId) {

        List<Pharmacy> pharmacies = pharmacyRepository.findByIsVerifiedTrue();
        Prescription rx = prescriptionId != null
                ? prescriptionRepository.findWithMedicinesByPrescriptionId(prescriptionId).orElse(null)
                : null;

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

            if (rx != null && !rx.getMedicines().isEmpty()) {
                evaluateStockForPrescription(response, p.getPharmacyId(), rx.getMedicines());
            } else {
                response.setStockStatus("IN_STOCK");
                response.setMatchedMedicinesCount(0);
            }

            result.add(response);
        }

        // Sort by distance (nearest first)
        result.sort(Comparator.comparing(PharmacySearchResponse::getDistanceKm));

        return result;
    }

    private void evaluateStockForPrescription(
            PharmacySearchResponse response,
            Long pharmacyId,
            List<PrescriptionMedicine> rxMeds) {

        int inStockCount = 0;
        int lowStockCount = 0;
        int outOfStockCount = 0;

        for (PrescriptionMedicine med : rxMeds) {
            Optional<PharmacyStock> stockOpt = stockRepository
                    .findStockByPharmacyAndMedicineName(pharmacyId, med.getMedicineName());

            PharmacySearchResponse.MedicineStockItem item = new PharmacySearchResponse.MedicineStockItem();
            item.setMedicineName(med.getMedicineName());

            if (stockOpt.isPresent()) {
                int qty = stockOpt.get().getQuantityAvailable();
                item.setQuantityAvailable(qty);
                item.setGenericName(stockOpt.get().getMedicine().getGenericName());

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
                item.setAvailability("IN_STOCK"); // Default to available in demo if general med
                inStockCount++;
            }

            response.getStockItems().add(item);
        }

        response.setMatchedMedicinesCount(rxMeds.size());

        if (outOfStockCount > 0) {
            response.setStockStatus("OUT_OF_STOCK");
        } else if (lowStockCount > 0) {
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
