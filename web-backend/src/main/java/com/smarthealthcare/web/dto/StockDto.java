package com.smarthealthcare.web.dto;

import com.smarthealthcare.web.entity.PharmacyStock;
import com.smarthealthcare.web.entity.StockStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockDto {
    private Long stockId;
    private Integer quantityAvailable;
    private BigDecimal unitPrice;
    private Integer minSafetyLevel;
    private LocalDateTime updatedAt;
    private Integer medicineId;
    private String genericName;
    private String brandName;
    private String category;
    private String strength;
    private StockStatus status;
    private double safetyPercentage;

    public static StockDto from(PharmacyStock stock, double safetyPercentage) {
        return StockDto.builder()
                .stockId(stock.getStockId())
                .quantityAvailable(stock.getQuantityAvailable())
                .unitPrice(stock.getUnitPrice())
                .minSafetyLevel(stock.getMinSafetyLevel())
                .updatedAt(stock.getUpdatedAt())
                .medicineId(stock.getMedicine() != null ? stock.getMedicine().getMedicineId() : null)
                .genericName(stock.getMedicine() != null ? stock.getMedicine().getGenericName() : null)
                .brandName(stock.getMedicine() != null ? stock.getMedicine().getBrandName() : null)
                .category(stock.getMedicine() != null ? stock.getMedicine().getCategory() : null)
                .strength(stock.getMedicine() != null ? stock.getMedicine().getStrength() : null)
                .status(StockStatus.from(stock.getQuantityAvailable(), stock.getMinSafetyLevel()))
                .safetyPercentage(safetyPercentage)
                .build();
    }
}
