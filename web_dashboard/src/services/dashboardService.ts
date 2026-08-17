import { API_BASE_URL, getAuthHeaders } from './api';
import { stockService } from './stockService';
import { profileService } from './profileService';

export interface StockMetrics {
  totalMedicines: number;
  inStock: number;
  lowStock: number;
  outOfStock: number;
}

export interface LowStockMedicine {
  id: string;
  name: string;
  currentStock: number;
  status: 'Low' | 'Critical';
}

export interface RecentUpdate {
  id: string;
  medicineName: string;
  action: string;
  timestamp: string;
}

export interface LocationStatus {
  status: string;
  address: string;
}

export interface DashboardData {
  metrics: StockMetrics;
  lowStockMedicines: LowStockMedicine[];
  recentUpdates: RecentUpdate[];
  locationStatus: LocationStatus;
  lastUpdated: string;
}

export const dashboardService = {
  /**
   * Resolves the dynamically mapped dashboard data from Spring Boot REST APIs.
   */
  async getDashboardData(): Promise<DashboardData> {
    // 1. Fetch KPI metrics from the dedicated stats endpoint
    const statsResponse = await fetch(`${API_BASE_URL}/api/web/dashboard/stats`, {
      method: 'GET',
      headers: getAuthHeaders()
    });

    if (!statsResponse.ok) {
      throw new Error('Failed to fetch dashboard metrics.');
    }

    const stats = await statsResponse.json();

    // 2. Fetch stock list for low stock items and updates
    let stocks = [];
    try {
      stocks = await stockService.getStock();
    } catch (e) {
      console.error('Failed to fetch stocks for dashboard compilation:', e);
    }

    // 3. Fetch profile for location widget
    let locationStatus: LocationStatus = {
      status: 'Location not configured ⚠️',
      address: 'Address not specified'
    };
    try {
      const profile = await profileService.getPharmacyProfile();
      locationStatus = {
        status: profile.location.configured ? 'Location configured ✓' : 'Location not configured ⚠️',
        address: profile.address || 'Address not specified'
      };
    } catch (e) {
      console.error('Failed to fetch profile for dashboard compilation:', e);
    }

    // Map metrics from backend DTO fields
    const total = stats.totalStockRecords;
    const inStock = stats.availableStock;
    const lowStock = stats.lowStock + stats.criticalStock;
    const outOfStock = stats.outOfStock;

    // Filter low stock list
    const lowStockMedicines: LowStockMedicine[] = stocks
      .filter(item => item.status === 'Low Stock' || item.status === 'Critical' || item.status === 'Out of Stock')
      .slice(0, 5)
      .map(item => ({
        id: item.id,
        name: item.medicineName,
        currentStock: item.currentStock,
        status: item.status === 'Critical' || item.status === 'Out of Stock' ? 'Critical' as const : 'Low' as const
      }));

    // Map recent updates
    const recentUpdates: RecentUpdate[] = [...stocks]
      .sort((a, b) => b.stockId - a.stockId)
      .slice(0, 4)
      .map(item => ({
        id: item.id,
        medicineName: item.medicineName,
        action: `Current inventory: ${item.currentStock} units`,
        timestamp: item.lastUpdated
      }));

    return {
      metrics: {
        totalMedicines: total,
        inStock: inStock,
        lowStock: lowStock,
        outOfStock: outOfStock
      },
      lowStockMedicines,
      recentUpdates,
      locationStatus,
      lastUpdated: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
  }
};

export default dashboardService;
