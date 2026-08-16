package com.smarthealthcare.web.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

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

    @Column(name = "name")
    private String name;

    @Column(name = "address")
    private String address;

    @Column(name = "contact_number", length = 20)
    private String contactNumber;

    @Column(name = "delivery_available")
    private Boolean deliveryAvailable;

    @Column(name = "operating_hours")
    private String operatingHours;

    @Column(name = "phone")
    private String phone;

    @Column(name = "is_verified")
    private Boolean isVerified;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

}
