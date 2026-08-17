import type { LoginCredentials, User } from '../types/auth';
import { API_BASE_URL } from './api';

export interface LoginResponse {
  user: User;
  token: string;
}

export const authService = {
  /**
   * Performs actual login calling the Spring Boot backend REST endpoint.
   */
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    const response = await fetch(`${API_BASE_URL}/api/web/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(credentials),
    });

    if (!response.ok) {
      let errorMessage = 'Login failed. Please try again.';
      try {
        const errorData = await response.json();
        if (errorData && errorData.message) {
          errorMessage = errorData.message;
        }
      } catch (e) {
        // Fallback for non-JSON or missing error body
      }
      throw new Error(errorMessage);
    }

    const data = await response.json();

    const user: User = {
      userId: data.userId,
      email: data.email,
      name: data.name,
      role: data.role,
      pharmacyId: data.pharmacyId,
    };

    return {
      user,
      token: data.token,
    };
  },

  /**
   * Performs client-side session cleanup.
   */
  async logout(): Promise<void> {
    // Stateless sessions only require client-side token disposal
  }
};
