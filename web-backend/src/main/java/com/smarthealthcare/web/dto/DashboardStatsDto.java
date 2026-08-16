package com.smarthealthcare.web.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsDto {
    private long totalMedicines;
    private long totalStockRecords;
    private long availableStock;
    private long lowStock;
    private long criticalStock;
    private long outOfStock;
}
