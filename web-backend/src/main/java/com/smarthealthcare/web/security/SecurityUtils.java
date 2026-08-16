package com.smarthealthcare.web.security;

import com.smarthealthcare.web.entity.User;
import com.smarthealthcare.web.exception.UserNotFoundException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class SecurityUtils {

    public static User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CustomUserDetails)) {
            throw new UserNotFoundException("No authenticated user found in security context.");
        }
        return ((CustomUserDetails) authentication.getPrincipal()).getUser();
    }

    public static Long getAuthenticatedUserId() {
        return getAuthenticatedUser().getUserId();
    }

    public static Long getAuthenticatedPharmacyId() {
        User user = getAuthenticatedUser();
        if (user.getPharmacy() == null) {
            throw new UserNotFoundException("Authenticated user is not associated with any pharmacy.");
        }
        return user.getPharmacy().getPharmacyId();
    }
}
