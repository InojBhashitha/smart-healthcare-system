import React, { useState, useEffect, useRef } from 'react';
import type { PharmacyProfile } from '../../services/profileService';
import { profileService } from '../../services/profileService';
import './Profile.css';

// Default coordinates (Colombo, Sri Lanka)
const DEFAULT_LAT = 6.9271;
const DEFAULT_LNG = 79.8612;

export const Profile: React.FC = () => {
  // --- State Variables ---
  const [profile, setProfile] = useState<PharmacyProfile | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [isEditingInfo, setIsEditingInfo] = useState<boolean>(false);
  const [isMapModalOpen, setIsMapModalOpen] = useState<boolean>(false);
  const [apiError, setApiError] = useState<string | null>(null);

  // Form Field States
  const [name, setName] = useState<string>('');
  const [contactNumber, setContactNumber] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [address, setAddress] = useState<string>('');
  const [formErrors, setFormErrors] = useState<{ [key: string]: string }>({});

  // Location Picker States
  const [tempLat, setTempLat] = useState<number>(DEFAULT_LAT);
  const [tempLng, setTempLng] = useState<number>(DEFAULT_LNG);
  const [geoStatus, setGeoStatus] = useState<'idle' | 'locating' | 'success' | 'error'>('idle');
  const [geoMessage, setGeoMessage] = useState<string>('');

  // Script loading state
  const [leafletLoaded, setLeafletLoaded] = useState<boolean>(false);

  // Map references
  const staticMapRef = useRef<any>(null);
  const pickerMapRef = useRef<any>(null);
  const pickerMarkerRef = useRef<any>(null);

  // --- Dynamic Leaflet Asset Injection ---
  useEffect(() => {
    // Check if Leaflet CSS exists
    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }

    // Check if Leaflet JS exists
    if (!document.getElementById('leaflet-js')) {
      const script = document.createElement('script');
      script.id = 'leaflet-js';
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.onload = () => setLeafletLoaded(true);
      document.body.appendChild(script);
    } else {
      // Leaflet is already loaded or being loaded
      const L = (window as any).L;
      if (L) {
        setLeafletLoaded(true);
      } else {
        const interval = setInterval(() => {
          if ((window as any).L) {
            setLeafletLoaded(true);
            clearInterval(interval);
          }
        }, 100);
      }
    }
  }, []);

  // --- Fetch Profile Data ---
  const fetchProfile = async () => {
    setLoading(true);
    setApiError(null);
    try {
      const data = await profileService.getPharmacyProfile();
      setProfile(data);
      setName(data.name);
      setContactNumber(data.contactNumber);
      setEmail(data.email);
      setAddress(data.address);
    } catch (err: any) {
      console.error('Failed to load profile details:', err);
      setApiError(err.message || 'Failed to load profile details from backend.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProfile();
  }, []);

  // --- Initialize Static Preview Map ---
  useEffect(() => {
    if (!leafletLoaded || !profile || !profile.location.configured) return;

    const L = (window as any).L;
    if (!L) return;

    const coords: [number, number] = [profile.location.latitude, profile.location.longitude];

    try {
      // Clean up previous instance
      if (staticMapRef.current) {
        staticMapRef.current.remove();
        staticMapRef.current = null;
      }

      // Initialize Map
      staticMapRef.current = L.map('static-map', {
        zoomControl: false,
        dragging: false,
        scrollWheelZoom: false,
        touchZoom: false,
        doubleClickZoom: false,
        boxZoom: false
      }).setView(coords, 14);

      // Tile Layer
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap'
      }).addTo(staticMapRef.current);

      // Marker icon fix (sometimes default CDN marker images fail, use clean SVG pin divIcon as fallback)
      const customPin = L.divIcon({
        html: '<div class="pin-bullet"></div>',
        className: 'custom-pin-marker',
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });

      L.marker(coords, { icon: customPin }).addTo(staticMapRef.current);
    } catch (err) {
      console.error('Error mounting static Leaflet view:', err);
    }

    return () => {
      if (staticMapRef.current) {
        staticMapRef.current.remove();
        staticMapRef.current = null;
      }
    };
  }, [leafletLoaded, profile]);

  // --- Initialize Interactive Picker Map ---
  useEffect(() => {
    if (!isMapModalOpen || !leafletLoaded) return;

    const L = (window as any).L;
    if (!L) return;

    const mapCenter: [number, number] = [tempLat, tempLng];

    try {
      if (pickerMapRef.current) {
        pickerMapRef.current.remove();
        pickerMapRef.current = null;
      }

      pickerMapRef.current = L.map('picker-map').setView(mapCenter, 13);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap'
      }).addTo(pickerMapRef.current);

      const customPin = L.divIcon({
        html: '<div class="pin-bullet"></div>',
        className: 'custom-pin-marker',
        iconSize: [24, 24],
        iconAnchor: [12, 12]
      });

      // Add Draggable Marker
      pickerMarkerRef.current = L.marker(mapCenter, {
        icon: customPin,
        draggable: true
      }).addTo(pickerMapRef.current);

      // Listen to Marker Drag
      pickerMarkerRef.current.on('dragend', () => {
        const position = pickerMarkerRef.current.getLatLng();
        setTempLat(position.lat);
        setTempLng(position.lng);
      });

      // Listen to Map Click to re-position pin
      pickerMapRef.current.on('click', (e: any) => {
        const coords = e.latlng;
        pickerMarkerRef.current.setLatLng(coords);
        setTempLat(coords.lat);
        setTempLng(coords.lng);
      });
    } catch (err) {
      console.error('Error mounting interactive Leaflet picker:', err);
    }

    return () => {
      if (pickerMapRef.current) {
        pickerMapRef.current.remove();
        pickerMapRef.current = null;
        pickerMarkerRef.current = null;
      }
    };
  }, [isMapModalOpen, leafletLoaded]);

  // --- HTML5 Geolocation API Handler ---
  const triggerGeolocation = () => {
    if (!navigator.geolocation) {
      setGeoStatus('error');
      setGeoMessage('Geolocation is not supported by your browser.');
      return;
    }

    setGeoStatus('locating');
    setGeoMessage('Requesting device coordinates...');

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        setTempLat(latitude);
        setTempLng(longitude);
        setGeoStatus('success');
        setGeoMessage('Location synced with browser GPS.');

        // Pan Map and re-position marker
        if (pickerMapRef.current && pickerMarkerRef.current) {
          const newCoords = (window as any).L.latLng(latitude, longitude);
          pickerMapRef.current.setView(newCoords, 15);
          pickerMarkerRef.current.setLatLng(newCoords);
        }
      },
      (error) => {
        setGeoStatus('error');
        if (error.code === error.PERMISSION_DENIED) {
          setGeoMessage('GPS access denied. Use search or pan manually.');
        } else {
          setGeoMessage('Coordinates timed out. Select coordinates manually.');
        }
      },
      { enableHighAccuracy: true, timeout: 6000 }
    );
  };

  // --- Form Handlers ---
  const validateForm = () => {
    const errors: { [key: string]: string } = {};
    if (!name.trim()) errors.name = 'Pharmacy name is required.';
    if (!address.trim()) errors.address = 'Business address is required.';
    if (!email.trim() || !/\S+@\S+\.\S+/.test(email)) errors.email = 'Please enter a valid email address.';
    if (!contactNumber.trim() || contactNumber.length < 8) errors.contactNumber = 'Enter a valid contact number.';
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleInfoSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm() || !profile) return;

    setLoading(true);
    setFormErrors({});
    try {
      const updatedProfile: PharmacyProfile = {
        ...profile,
        name: name.trim(),
        contactNumber: contactNumber.trim(),
        email: email.trim(),
        address: address.trim()
      };
      const result = await profileService.updatePharmacyProfile(updatedProfile);
      setProfile(result);
      setIsEditingInfo(false);
    } catch (err: any) {
      console.error('Failed to update pharmacy details:', err);
      setFormErrors(prev => ({ ...prev, form: err.message || 'Failed to update pharmacy details.' }));
    } finally {
      setLoading(false);
    }
  };

  const handleInfoCancel = () => {
    if (profile) {
      setName(profile.name);
      setContactNumber(profile.contactNumber);
      setEmail(profile.email);
      setAddress(profile.address);
    }
    setFormErrors({});
    setIsEditingInfo(false);
  };

  // --- Location Map Operations ---
  const openLocationPicker = () => {
    if (profile && profile.location.configured) {
      setTempLat(profile.location.latitude);
      setTempLng(profile.location.longitude);
    } else {
      setTempLat(DEFAULT_LAT);
      setTempLng(DEFAULT_LNG);
    }
    setGeoStatus('idle');
    setGeoMessage('');
    setIsMapModalOpen(true);
  };

  const confirmLocationSelection = async () => {
    if (!profile) return;
    setLoading(true);
    setApiError(null);
    try {
      const lat = Number(tempLat.toFixed(6));
      const lng = Number(tempLng.toFixed(6));
      const newLoc = await profileService.updatePharmacyLocation(lat, lng);
      setProfile(prev => prev ? {
        ...prev,
        location: newLoc
      } : null);
      setIsMapModalOpen(false);
    } catch (err: any) {
      console.error('Failed to save coordinates:', err);
      setApiError(err.message || 'Failed to save location coordinates.');
      setIsMapModalOpen(false);
    } finally {
      setLoading(false);
    }
  };

  // Render Loader Skeleton
  if (loading && !profile) {
    return (
      <div className="profile-page">
        <div className="skeleton-box skeleton-header" />
        <div className="profile-grid">
          <div className="skeleton-box skeleton-main" style={{ height: '350px' }} />
          <div className="skeleton-box skeleton-main" style={{ height: '350px' }} />
        </div>
      </div>
    );
  }

  return (
    <div className="profile-page">
      {apiError && (
        <div style={{
          backgroundColor: '#fef2f2',
          border: '1px solid #fee2e2',
          borderRadius: '6px',
          color: '#991b1b',
          padding: '12px 16px',
          marginBottom: '20px',
          fontSize: '14px'
        }}>
          {apiError}
        </div>
      )}
      {/* Header */}
      <header className="profile-header">
        <h1 className="profile-title">Profile & Location</h1>
        <p className="profile-subtitle">Configure business profiles, geolocations, and mobile locator anchors.</p>
      </header>

      <div className="profile-grid">
        {/* Left Column: General Information Card */}
        <div className="card-container">
          <div className="card-header-row">
            <h2 className="card-title">Pharmacy Details</h2>
            {!isEditingInfo && (
              <button onClick={() => setIsEditingInfo(true)} className="btn btn-secondary">
                Edit Details
              </button>
            )}
          </div>

          {isEditingInfo ? (
            <form onSubmit={handleInfoSubmit}>
              <div className="info-list">
                {/* Pharmacy Name */}
                <div className="info-item">
                  <label className="info-label" htmlFor="pharm-name">Pharmacy Name</label>
                  <input
                    id="pharm-name"
                    type="text"
                    className="info-input"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                  {formErrors.name && <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.name}</span>}
                </div>

                {/* Email Address */}
                <div className="info-item">
                  <label className="info-label" htmlFor="pharm-email">Contact Email</label>
                  <input
                    id="pharm-email"
                    type="email"
                    className="info-input"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                  {formErrors.email && <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.email}</span>}
                </div>

                {/* Contact Phone */}
                <div className="info-item">
                  <label className="info-label" htmlFor="pharm-phone">Contact Number</label>
                  <input
                    id="pharm-phone"
                    type="text"
                    className="info-input"
                    value={contactNumber}
                    onChange={(e) => setContactNumber(e.target.value)}
                  />
                  {formErrors.contactNumber && <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.contactNumber}</span>}
                </div>

                {/* Physical Address */}
                <div className="info-item">
                  <label className="info-label" htmlFor="pharm-addr">Business Address</label>
                  <textarea
                    id="pharm-addr"
                    className="info-input"
                    rows={3}
                    style={{ resize: 'none' }}
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                  />
                  {formErrors.address && <span className="field-error" style={{ color: '#de3545', fontSize: '12px' }}>{formErrors.address}</span>}
                </div>
              </div>
              {formErrors.form && (
                <div style={{ color: '#de3545', fontSize: '13px', marginTop: '12px', fontWeight: '500' }}>
                  {formErrors.form}
                </div>
              )}
              <div style={{ display: 'flex', gap: '12px', marginTop: '24px', justifyContent: 'flex-end' }}>
                <button type="button" onClick={handleInfoCancel} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Details
                </button>
              </div>
            </form>
          ) : (
            <div className="info-list">
              <div className="info-item">
                <span className="info-label">Pharmacy Name</span>
                <span className="info-value">{profile?.name}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Contact Email</span>
                <span className="info-value">{profile?.email}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Contact Number</span>
                <span className="info-value">{profile?.contactNumber}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Business Address</span>
                <span className="info-value">{profile?.address}</span>
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Pharmacy Location Management */}
        <div className="card-container">
          <div className="card-header-row">
            <h2 className="card-title">Pharmacy Location</h2>
            {/* Status Alert Badge */}
            {profile?.location.configured ? (
              <div className="status-badge status-configured">
                <span className="status-dot" />
                <span>Configured</span>
              </div>
            ) : (
              <div className="status-badge status-unconfigured">
                <span className="status-dot" />
                <span>Not Configured</span>
              </div>
            )}
          </div>

          {/* Coordinates Details Grid */}
          <div className="coords-grid">
            <div className="coord-box">
              <span className="coord-label">Latitude</span>
              <span className="coord-val">
                {profile?.location.configured ? profile.location.latitude : 'Not Configured'}
              </span>
            </div>
            <div className="coord-box">
              <span className="coord-label">Longitude</span>
              <span className="coord-val">
                {profile?.location.configured ? profile.location.longitude : 'Not Configured'}
              </span>
            </div>
          </div>

          {/* Location details card */}
          {profile?.location.configured && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <span className="info-label" style={{ fontSize: '11px' }}>Geolocated Address</span>
              <span className="info-value" style={{ fontSize: '14px', color: '#475569' }}>
                📍 {profile.address}
              </span>
            </div>
          )}

          {/* Map Preview Element */}
          <div className="map-preview-container">
            {profile?.location.configured ? (
              <div id="static-map" className="static-map-view" />
            ) : (
              <div className="static-map-view" style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                backgroundColor: '#f1f5f9',
                color: '#64748b',
                border: '1px dashed #cbd5e1',
                borderRadius: '8px'
              }}>
                No saved geolocation pin to preview.
              </div>
            )}
          </div>

          <button onClick={openLocationPicker} className="btn btn-primary" style={{ width: '100%' }}>
            {profile?.location.configured ? 'Change Location Pin' : 'Configure Geolocation'}
          </button>
        </div>
      </div>

      {/* --- LOCATION PICKER MAP MODAL --- */}
      {isMapModalOpen && (
        <div className="modal-backdrop" onClick={() => setIsMapModalOpen(false)}>
          <div className="modal-content" style={{ maxWidth: '600px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title">Interactive Map Picker</h3>
              <button onClick={() => setIsMapModalOpen(false)} className="modal-close-btn">&times;</button>
            </div>
            <div className="modal-body">
              {/* Geolocation permit notifications */}
              {geoStatus !== 'idle' && (
                <div className={`picker-geo-alert ${geoStatus === 'error' ? 'error-alert' : ''}`}>
                  <span>{geoMessage}</span>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                <span style={{ fontSize: '13px', color: '#64748b' }}>
                  Drag the marker or click coordinates to pinpoint location.
                </span>
                <button type="button" onClick={triggerGeolocation} className="btn btn-secondary btn-sm" style={{ padding: '6px 12px', fontSize: '12px' }}>
                  Locate Me
                </button>
              </div>

              {/* Leaflet Picker element */}
              <div id="picker-map" className="picker-map-view" />

              {/* Coordinates display during selection */}
              <div className="coords-grid" style={{ marginTop: '16px' }}>
                <div className="coord-box">
                  <span className="coord-label">Selected Latitude</span>
                  <span className="coord-val">{tempLat.toFixed(6)}</span>
                </div>
                <div className="coord-box">
                  <span className="coord-label">Selected Longitude</span>
                  <span className="coord-val">{tempLng.toFixed(6)}</span>
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button type="button" onClick={() => setIsMapModalOpen(false)} className="btn btn-secondary">
                Cancel
              </button>
              <button type="button" onClick={confirmLocationSelection} className="btn btn-primary">
                Confirm Location
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Profile;
