export type StockStatus = 'Available' | 'Low Stock' | 'Critical' | 'Out of Stock';

export interface Medicine {
  medicineId: number;
  genericName: string;
  brandName: string;
  category: string;
  strength: string;
  dosageForm: string | null;
  description: string | null;
  sideEffects: string | null;
}

export interface StockItem {
  id: string;
  stockId: number;
  medicineName: string;
  category: string;
  strength: string;
  currentStock: number;
  minStockLevel: number;
  status: StockStatus;
  lastUpdated: string;
  unitPrice: number;
  medicineId: number;
  safetyPercentage: number;
  genericName: string;
  brandName: string;
}
