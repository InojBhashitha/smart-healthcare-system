/**
 * Mock API service layer
 * Mimics asynchronous API calls with configurable delay to simulate actual REST requests.
 */

export const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Future base URL can be read from environment
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';
