import React from 'react';
import './Stock.css';

export const Stock: React.FC = () => {
  return (
    <div className="page-container">
      <header className="page-header">
        <h1 className="page-title">Stock Management</h1>
        <p className="page-description">Manage pharmacy inventory, medicine supplies, and stock levels.</p>
      </header>
      <div className="placeholder-content">
        <div className="info-card">
          <h3>Inventory System Placeholder</h3>
          <p>This module will be connected to the Spring Boot backend inventory APIs in a future phase.</p>
        </div>
      </div>
    </div>
  );
};

export default Stock;
