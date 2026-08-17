package com.smarthealthcare.web.exception;

public class UnauthorizedPharmacyAccessException extends RuntimeException {
    public UnauthorizedPharmacyAccessException(String message) {
        super(message);
    }
}
