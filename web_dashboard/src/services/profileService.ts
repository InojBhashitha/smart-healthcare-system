import { API_BASE_URL, getAuthHeaders } from './api';

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

const mapBackendToProfile = (user: any): PharmacyProfile => {
  const pharmacy = user.pharmacy;
  return {
    name: pharmacy ? pharmacy.name : user.name,
    contactNumber: pharmacy ? (pharmacy.contactNumber || pharmacy.phone || user.phone || '') : (user.phone || ''),
    email: user.email,
    address: pharmacy ? (pharmacy.address || '') : '',
    location: {
      latitude: pharmacy && pharmacy.latitude != null ? pharmacy.latitude : 6.9271,
      longitude: pharmacy && pharmacy.longitude != null ? pharmacy.longitude : 79.8612,
      configured: pharmacy && pharmacy.latitude != null && pharmacy.longitude != null,
      lastUpdated: 'Recently'
    }
  };
};

export const profileService = {
  /**
   * Fetches the current authenticated user's pharmacy profile.
   */
  async getPharmacyProfile(): Promise<PharmacyProfile> {
    const response = await fetch(`${API_BASE_URL}/api/web/profile`, {
      method: 'GET',
      headers: getAuthHeaders(),
    });

    if (!response.ok) {
      throw new Error('Failed to fetch pharmacy profile from server.');
    }

    const data = await response.json();
    return mapBackendToProfile(data);
  },

  /**
   * Updates the pharmacy/user profile details (name, email, phone, address).
   */
  async updatePharmacyProfile(updated: PharmacyProfile): Promise<PharmacyProfile> {
    const payload = {
      pharmacyName: updated.name,
      email: updated.email,
      phone: updated.contactNumber,
      address: updated.address
    };

    const response = await fetch(`${API_BASE_URL}/api/web/profile`, {
      method: 'PUT',
      headers: getAuthHeaders(),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      let errorMessage = 'Failed to update pharmacy details.';
      try {
        const errorData = await response.json();
        if (errorData && errorData.message) {
          errorMessage = errorData.message;
        }
      } catch (e) {
        // Ignore parsing errors
      }
      throw new Error(errorMessage);
    }

    const data = await response.json();
    return mapBackendToProfile(data);
  },

  /**
   * Updates the pharmacy coordinates (latitude, longitude).
   */
  async updatePharmacyLocation(latitude: number, longitude: number): Promise<PharmacyLocation> {
    const url = new URL(`${API_BASE_URL}/api/web/profile/location`);
    url.searchParams.append('latitude', latitude.toString());
    url.searchParams.append('longitude', longitude.toString());

    const response = await fetch(url.toString(), {
      method: 'PUT',
      headers: getAuthHeaders(),
    });

    if (!response.ok) {
      throw new Error('Failed to update pharmacy location coordinates.');
    }

    const data = await response.json(); // returns Pharmacy entity
    return {
      latitude: data.latitude,
      longitude: data.longitude,
      configured: data.latitude != null && data.longitude != null,
      lastUpdated: 'Recently'
    };
  }
};

export default profileService;
