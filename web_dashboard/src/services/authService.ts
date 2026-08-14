import type { LoginCredentials, User } from '../types/auth';
import { delay } from './api';

// Hardcoded development credentials as requested
const MOCK_EMAIL = 'pharmacy1@example.com';
const MOCK_PASSWORD = 'pharmacy123';

const MOCK_USER: User = {
  id: 'pharm-001',
  email: MOCK_EMAIL,
  name: 'HealthPlus Pharmacy Central',
  role: 'pharmacy',
};

export interface LoginResponse {
  user: User;
  token: string;
}

export const authService = {
  /**
   * Performs mock login with hardcoded credentials.
   * Simulates network latency of 800ms.
   */
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    await delay(800);

    const email = credentials.email.trim().toLowerCase();
    const password = credentials.password;

    if (email === MOCK_EMAIL && password === MOCK_PASSWORD) {
      return {
        user: MOCK_USER,
        token: 'mock-jwt-token-xyz-123',
      };
    }

    throw new Error('Invalid email or password. Please try again.');
  },

  /**
   * Performs mock logout.
   */
  async logout(): Promise<void> {
    await delay(300);
  }
};
