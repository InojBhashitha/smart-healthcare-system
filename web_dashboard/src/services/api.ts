export const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8081';

export const getAuthHeaders = (): HeadersInit => {
  const session = localStorage.getItem('pharmacy_dashboard_session');
  if (session) {
    try {
      const { token } = JSON.parse(session);
      if (token) {
        return {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        };
      }
    } catch (e) {
      console.error('Failed to parse session token:', e);
    }
  }
  return {
    'Content-Type': 'application/json'
  };
};
