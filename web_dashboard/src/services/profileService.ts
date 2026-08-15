import { delay } from './api';

export interface PharmacyLocation {
  latitude: number;
  longitude: number;
  configured: boolean;
  lastUpdated: string;
}

export interface PharmacyProfile {
  name: string;
  contactNumber: string;
  email: string;
  address: string;
  location: PharmacyLocation;
}

// Memory database for pharmacy profile details
let mockProfile: PharmacyProfile = {
  name: 'HealthPlus Pharmacy Central',
  contactNumber: '+94 11 234 5678',
  email: 'pharmacy1@example.com',
  address: '123 Union Place, Colombo 02, Sri Lanka',
  location: {
    latitude: 6.9271,
    longitude: 79.8612,
    configured: true,
    lastUpdated: 'Today'
  }
};

export const profileService = {
  /**
   * Fetches mock profile details with 400ms delay.
   */
  async getPharmacyProfile(): Promise<PharmacyProfile> {
    await delay(400);
    return { ...mockProfile };
  },

  /**
   * Updates mock profile details with 400ms delay.
   */
  async updatePharmacyProfile(updated: PharmacyProfile): Promise<PharmacyProfile> {
    await delay(400);
    mockProfile = { ...updated };
    return { ...mockProfile };
  }
};

export default profileService;
