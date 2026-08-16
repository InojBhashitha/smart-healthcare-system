import { API_BASE_URL, getAuthHeaders } from './api';
import type { Medicine } from '../types/stock';

export const medicineService = {
  /**
   * Retrieves all medicines or searches them by query keyword.
   */
  async getMedicines(query?: string): Promise<Medicine[]> {
    const url = new URL(`${API_BASE_URL}/api/web/medicines`);
    if (query) {
      url.searchParams.append('query', query);
    }
    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    if (!response.ok) {
      throw new Error('Failed to fetch medicines data');
    }

    return response.json();
  }
};

export default medicineService;
