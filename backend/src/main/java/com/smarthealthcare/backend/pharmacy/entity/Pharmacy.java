package com.smarthealthcare.backend.pharmacy.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "pharmacies")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Pharmacy {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pharmacy_id")
    private Long pharmacyId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "latitude", nullable = false)
    private Double latitude;

    @Column(name = "longitude", nullable = false)
    private Double longitude;

    @Column(name = "phone")
    private String phone;

    @Column(name = "operating_hours")
    private String operatingHours;

    @Column(name = "delivery_available")
    private Boolean deliveryAvailable = false;

    @Column(name = "contact_number")
    private String contactNumber;

    @Column(name = "is_verified", nullable = false)
    private Boolean isVerified = true;
}
