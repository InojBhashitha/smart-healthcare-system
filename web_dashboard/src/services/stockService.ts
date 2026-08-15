import { delay } from './api';

export type StockStatus = 'Available' | 'Low Stock' | 'Critical' | 'Out of Stock';

export interface StockItem {
  id: string;
  medicineName: string;
  category: string;
  strength: string;
  currentStock: number;
  minStockLevel: number;
  status: StockStatus;
  lastUpdated: string;
}

export interface StockSummary {
  totalMedicines: number;
  inStock: number;
  lowStock: number;
  outOfStock: number;
}

export interface MedicineMetadata {
  name: string;
  category: string;
  strength: string;
}

// Master Medicines database for searchable autocomplete
export const MASTER_MEDICINES: MedicineMetadata[] = [
  { name: 'Paracetamol', category: 'Analgesic', strength: '500mg' },
  { name: 'Amoxicillin', category: 'Antibiotic', strength: '500mg' },
  { name: 'Cetirizine', category: 'Antihistamine', strength: '10mg' },
  { name: 'Metformin', category: 'Antidiabetic', strength: '850mg' },
  { name: 'Atorvastatin', category: 'Cholesterol', strength: '20mg' },
  { name: 'Omeprazole', category: 'Antacid', strength: '20mg' },
  { name: 'Amlodipine', category: 'Antihypertensive', strength: '5mg' },
  { name: 'Ibuprofen', category: 'NSAID', strength: '400mg' },
  { name: 'Azithromycin', category: 'Antibiotic', strength: '250mg' },
  { name: 'Losartan', category: 'Antihypertensive', strength: '50mg' },
  { name: 'Salbutamol', category: 'Bronchodilator', strength: '100mcg' },
  { name: 'Furosemide', category: 'Diuretic', strength: '40mg' },
  { name: 'Clopidogrel', category: 'Antiplatelet', strength: '75mg' }
];

// Seed Mock Stock Items
const initialStockList: StockItem[] = [
  {
    id: 'STK-001',
    medicineName: 'Paracetamol',
    category: 'Analgesic',
    strength: '500mg',
    currentStock: 450,
    minStockLevel: 100,
    status: 'Available',
    lastUpdated: '10 mins ago'
  },
  {
    id: 'STK-002',
    medicineName: 'Amoxicillin',
    category: 'Antibiotic',
    strength: '500mg',
    currentStock: 8,
    minStockLevel: 50,
    status: 'Critical',
    lastUpdated: '25 mins ago'
  },
  {
    id: 'STK-003',
    medicineName: 'Cetirizine',
    category: 'Antihistamine',
    strength: '10mg',
    currentStock: 45,
    minStockLevel: 50,
    status: 'Low Stock',
    lastUpdated: '1 hour ago'
  },
  {
    id: 'STK-004',
    medicineName: 'Metformin',
    category: 'Antidiabetic',
    strength: '850mg',
    currentStock: 120,
    minStockLevel: 40,
    status: 'Available',
    lastUpdated: '2 hours ago'
  },
  {
    id: 'STK-005',
    medicineName: 'Atorvastatin',
    category: 'Cholesterol',
    strength: '20mg',
    currentStock: 0,
    minStockLevel: 30,
    status: 'Out of Stock',
    lastUpdated: '5 mins ago'
  },
  {
    id: 'STK-006',
    medicineName: 'Omeprazole',
    category: 'Antacid',
    strength: '20mg',
    currentStock: 250,
    minStockLevel: 60,
    status: 'Available',
    lastUpdated: '1 day ago'
  },
  {
    id: 'STK-007',
    medicineName: 'Amlodipine',
    category: 'Antihypertensive',
    strength: '5mg',
    currentStock: 35,
    minStockLevel: 40,
    status: 'Low Stock',
    lastUpdated: '3 hours ago'
  },
  {
    id: 'STK-008',
    medicineName: 'Ibuprofen',
    category: 'NSAID',
    strength: '400mg',
    currentStock: 90,
    minStockLevel: 50,
    status: 'Available',
    lastUpdated: '4 hours ago'
  },
  {
    id: 'STK-009',
    medicineName: 'Azithromycin',
    category: 'Antibiotic',
    strength: '250mg',
    currentStock: 5,
    minStockLevel: 20,
    status: 'Critical',
    lastUpdated: '2 days ago'
  },
  {
    id: 'STK-010',
    medicineName: 'Losartan',
    category: 'Antihypertensive',
    strength: '50mg',
    currentStock: 15,
    minStockLevel: 30,
    status: 'Low Stock',
    lastUpdated: '5 hours ago'
  },
  {
    id: 'STK-011',
    medicineName: 'Salbutamol',
    category: 'Bronchodilator',
    strength: '100mcg',
    currentStock: 80,
    minStockLevel: 25,
    status: 'Available',
    lastUpdated: '3 days ago'
  },
  {
    id: 'STK-012',
    medicineName: 'Furosemide',
    category: 'Diuretic',
    strength: '40mg',
    currentStock: 0,
    minStockLevel: 15,
    status: 'Out of Stock',
    lastUpdated: '12 hours ago'
  },
  {
    id: 'STK-013',
    medicineName: 'Clopidogrel',
    category: 'Antiplatelet',
    strength: '75mg',
    currentStock: 200,
    minStockLevel: 40,
    status: 'Available',
    lastUpdated: '4 days ago'
  }
];

// Helper to calculate status based on current stock vs min stock level
export const calculateStatus = (current: number, min: number): StockStatus => {
  if (current === 0) return 'Out of Stock';
  if (current < min * 0.2) return 'Critical';
  if (current < min) return 'Low Stock';
  return 'Available';
};

export const stockService = {
  /**
   * Returns copy of mock stock items with delay.
   */
  async getStock(): Promise<StockItem[]> {
    await delay(500);
    return [...initialStockList];
  },

  /**
   * Helper to retrieve stock summary metrics.
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
