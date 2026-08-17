package com.smarthealthcare.web.entity;

public enum StockStatus {
    AVAILABLE,
    LOW_STOCK,
    CRITICAL,
    OUT_OF_STOCK;

    public static StockStatus from(Integer quantity, Integer minSafetyLevel) {
        if (quantity == null || quantity <= 0) {
            return OUT_OF_STOCK;
        }
        int safety = (minSafetyLevel != null) ? minSafetyLevel : 0;
        if (quantity >= safety) {
            return AVAILABLE;
        }
        if (quantity < (safety / 2.0)) {
            return CRITICAL;
        }
        return LOW_STOCK;
    }
}
