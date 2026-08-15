import { delay } from './api';

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
   * Fetches mock dashboard data with a simulated network delay of 600ms.
   */
  async getDashboardData(): Promise<DashboardData> {
    await delay(600);
    
    return {
      metrics: {
        totalMedicines: 128,
        inStock: 102,
        lowStock: 18,
        outOfStock: 8
      },
      lowStockMedicines: [
        { id: '1', name: 'Amoxicillin 500mg', currentStock: 8, status: 'Low' },
        { id: '2', name: 'Cetirizine 10mg', currentStock: 3, status: 'Critical' },
        { id: '3', name: 'Paracetamol 500mg', currentStock: 15, status: 'Low' },
        { id: '4', name: 'Metformin 850mg', currentStock: 2, status: 'Critical' },
        { id: '5', name: 'Ibuprofen 400mg', currentStock: 9, status: 'Low' }
      ],
      recentUpdates: [
        { id: '1', medicineName: 'Paracetamol 500mg', action: 'Restocked +500 units', timestamp: '5 mins ago' },
        { id: '2', medicineName: 'Amoxicillin 500mg', action: 'Dispensed 30 units', timestamp: '20 mins ago' },
        { id: '3', medicineName: 'Cetirizine 10mg', action: 'Stock alert triggered', timestamp: '1 hour ago' },
        { id: '4', medicineName: 'Atorvastatin 20mg', action: 'Updated price', timestamp: '3 hours ago' }
      ],
      locationStatus: {
        status: 'Location configured ✓',
        address: 'Colombo, Sri Lanka'
      },
      lastUpdated: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };
  }
};
