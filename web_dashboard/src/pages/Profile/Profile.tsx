import React from 'react';
import './Profile.css';

export const Profile: React.FC = () => {
  return (
    <div className="page-container">
      <header className="page-header">
        <h1 className="page-title">Pharmacy Profile</h1>
        <p className="page-description">Manage pharmacy registration details, contact information, and business hours.</p>
      </header>
      <div className="placeholder-content">
        <div className="info-card">
          <h3>Profile Dashboard Placeholder</h3>
          <p>This module will allow updating pharmacy details and location coordinate markers in a future phase.</p>
        </div>
      </div>
    </div>
  );
};

export default Profile;
