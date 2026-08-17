import { API_BASE_URL, getAuthHeaders } from './api';
import type { StockItem, StockStatus } from '../types/stock';

export interface StockSummary {
  totalMedicines: number;
  inStock: number;
  lowStock: number;
  outOfStock: number;
}

const mapStatus = (backendStatus: string): StockStatus => {
  switch (backendStatus) {
    case 'AVAILABLE': return 'Available';
    case 'LOW_STOCK': return 'Low Stock';
    case 'CRITICAL': return 'Critical';
    case 'OUT_OF_STOCK': return 'Out of Stock';
    default: return 'Available';
  }
};

const formatLastUpdated = (dateString: string): string => {
  if (!dateString) return 'Never';
  try {
    const date = new Date(dateString);
    return date.toLocaleString();
  } catch (e) {
    return dateString;
  }
};

export const stockService = {
  /**
   * Fetches the current user's pharmacy stocks from the backend.
   */
  async getStock(): Promise<StockItem[]> {
    const response = await fetch(`${API_BASE_URL}/api/web/stock`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    if (!response.ok) {
      throw new Error('Failed to fetch stock items from server.');
    }

    const data = await response.json();
    return data.map((dto: any) => ({
      id: `STK-${dto.stockId}`,
      stockId: dto.stockId,
      medicineName: dto.brandName ? `${dto.brandName} (${dto.genericName})` : dto.genericName,
      category: dto.category || 'General',
      strength: dto.strength || 'N/A',
      currentStock: dto.quantityAvailable,
      minStockLevel: dto.minSafetyLevel,
      status: mapStatus(dto.status),
      lastUpdated: formatLastUpdated(dto.updatedAt),
      unitPrice: dto.unitPrice,
      medicineId: dto.medicineId,
      safetyPercentage: dto.safetyPercentage,
      genericName: dto.genericName,
      brandName: dto.brandName
    }));
  },

  /**
   * Adds a new stock item to the pharmacy inventory.
   */
  async addStock(medicineId: number, quantity: number, minLevel: number, price: number): Promise<StockItem> {
    const response = await fetch(`${API_BASE_URL}/api/web/stock?medicineId=${medicineId}`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        quantityAvailable: quantity,
        unitPrice: price,
        minSafetyLevel: minLevel
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to add stock record.');
    }

    const dto = await response.json();
    return {
      id: `STK-${dto.stockId}`,
      stockId: dto.stockId,
      medicineName: dto.brandName ? `${dto.brandName} (${dto.genericName})` : dto.genericName,
      category: dto.category || 'General',
      strength: dto.strength || 'N/A',
      currentStock: dto.quantityAvailable,
      minStockLevel: dto.minSafetyLevel,
      status: mapStatus(dto.status),
      lastUpdated: formatLastUpdated(dto.updatedAt),
      unitPrice: dto.unitPrice,
      medicineId: dto.medicineId,
      safetyPercentage: dto.safetyPercentage,
      genericName: dto.genericName,
      brandName: dto.brandName
    };
  },

  /**
   * Updates an existing stock item in the pharmacy inventory.
   */
  async updateStock(stockId: number, quantity: number, minLevel: number, price: number): Promise<StockItem> {
    const response = await fetch(`${API_BASE_URL}/api/web/stock/${stockId}`, {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        quantityAvailable: quantity,
        unitPrice: price,
        minSafetyLevel: minLevel
      }),
    });

    if (!response.ok) {
      throw new Error('Failed to update stock record.');
    }

    const dto = await response.json();
    return {
      id: `STK-${dto.stockId}`,
      stockId: dto.stockId,
      medicineName: dto.brandName ? `${dto.brandName} (${dto.genericName})` : dto.genericName,
      category: dto.category || 'General',
      strength: dto.strength || 'N/A',
      currentStock: dto.quantityAvailable,
      minStockLevel: dto.minSafetyLevel,
      status: mapStatus(dto.status),
      lastUpdated: formatLastUpdated(dto.updatedAt),
      unitPrice: dto.unitPrice,
      medicineId: dto.medicineId,
      safetyPercentage: dto.safetyPercentage,
      genericName: dto.genericName,
      brandName: dto.brandName
    };
  },

  /**
   * Deletes a stock item from the pharmacy inventory.
   */
  async deleteStock(stockId: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/api/web/stock/${stockId}`, {
      method: 'DELETE',
      headers: getAuthHeaders(),
    });

    if (!response.ok) {
      throw new Error('Failed to delete stock record.');
    }
  },

  /**
   * Helper to retrieve stock summary metrics from item list.
   */
  calculateSummary(items: StockItem[]): StockSummary {
    const totalMedicines = items.length;
    const inStock = items.filter(item => item.currentStock > 0).length;
    const lowStock = items.filter(item => item.status === 'Low Stock' || item.status === 'Critical').length;
    const outOfStock = items.filter(item => item.currentStock === 0).length;

    return {
      totalMedicines,
      inStock,
      lowStock,
      outOfStock
    };
  }
};

export default stockService;
