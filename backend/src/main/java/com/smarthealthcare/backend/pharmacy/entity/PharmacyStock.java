package com.smarthealthcare.backend.pharmacy.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.smarthealthcare.backend.medicine.entity.Medicine;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "pharmacy_stocks")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PharmacyStock {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stock_id")
    private Long stockId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pharmacy_id", nullable = false)
    @JsonIgnore
    private Pharmacy pharmacy;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "medicine_id", nullable = false)
    private Medicine medicine;

    @Column(name = "unit_price", precision = 10, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "quantity_available", nullable = false)
    private Integer quantityAvailable = 0;
}
