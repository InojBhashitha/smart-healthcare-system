import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/authContext';
import { dashboardService, type DashboardData } from '../../services/dashboardService';
import './Dashboard.css';

export const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    let active = true;
    
    const fetchDashboard = async () => {
      try {
        const result = await dashboardService.getDashboardData();
        if (active) {
          setData(result);
          setLoading(false);
        }
      } catch (err) {
        console.error('Failed to load dashboard data:', err);
      }
    };

    fetchDashboard();
    return () => {
      active = false;
    };
  }, []);

  const navigateToStock = () => {
    window.location.hash = '#/stock';
  };

  if (loading || !data) {
    return (
      <div className="dashboard-page">
        <div className="skeleton-box skeleton-header" />
        <div className="skeleton-grid">
          <div className="skeleton-box skeleton-card" />
          <div className="skeleton-box skeleton-card" />
          <div className="skeleton-box skeleton-card" />
          <div className="skeleton-box skeleton-card" />
        </div>
        <div className="dashboard-grid">
          <div className="skeleton-box skeleton-main" />
          <div className="skeleton-box skeleton-main" />
        </div>
      </div>
    );
  }

  // Math variables for SVG Donut chart calculation
  const total = data.metrics.totalMedicines;
  const inStock = data.metrics.inStock;
  const lowStock = data.metrics.lowStock;
  const outOfStock = data.metrics.outOfStock;

  const circ = 2 * Math.PI * 50; // Radius = 50, Circ = 314.159

  // Proportions
  const inStockLen = (inStock / total) * circ;
  const lowStockLen = (lowStock / total) * circ;
  const outStockLen = (outOfStock / total) * circ;

  // Offsets
  const inStockOffset = 0;
  const lowStockOffset = -inStockLen;
  const outStockOffset = -(inStockLen + lowStockLen);

  return (
    <div className="dashboard-page">
      {/* Top Header Section */}
      <header className="dashboard-header">
        <div>
          <h1 className="welcome-title">Good Morning, {user?.name || 'Pharmacy Central'}</h1>
          <p className="welcome-subtitle">Here's your pharmacy stock overview.</p>
        </div>
        <div className="last-updated">
          <span>Last updated: {data.lastUpdated}</span>
        </div>
      </header>

      {/* Summary metrics KPI Row */}
      <div className="kpi-grid">
        {/* Total Medicines */}
        <div className="kpi-card kpi-total">
          <div className="kpi-info">
            <span className="kpi-title">Total Medicines</span>
            <span className="kpi-value">{total}</span>
            <span className="kpi-supporting">Registered items</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </div>
        </div>

        {/* In Stock */}
        <div className="kpi-card kpi-instock">
          <div className="kpi-info">
            <span className="kpi-title">In Stock</span>
            <span className="kpi-value">{inStock}</span>
            <span className="kpi-supporting">Active availability</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>

        {/* Low Stock */}
        <div className="kpi-card kpi-lowstock">
          <div className="kpi-info">
            <span className="kpi-title">Low Stock</span>
            <span className="kpi-value">{lowStock}</span>
            <span className="kpi-supporting">Action required</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
        </div>

        {/* Out of Stock */}
        <div className="kpi-card kpi-outstock">
          <div className="kpi-info">
            <span className="kpi-title">Out of Stock</span>
            <span className="kpi-value">{outOfStock}</span>
            <span className="kpi-supporting">Reorder immediately</span>
          </div>
          <div className="kpi-icon-wrapper">
            <svg className="kpi-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path strokeLinecap="round" strokeLinejoin="round" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
      </div>

      {/* Main Two Column Grid layout */}
      <div className="dashboard-grid">
        {/* Left Column: Analytics + Low Stock */}
        <div className="grid-column">
          {/* Stock Overview Analytics (SVG Donut Chart) */}
          <div className="card-container">
            <div className="card-header">
              <h2 className="card-title">Stock Overview</h2>
            </div>
            <div className="analytics-content">
              <div className="chart-wrapper">
                <svg className="chart-svg" width="160" height="160" viewBox="0 0 120 120">
                  <circle className="donut-bg" cx="60" cy="60" r="50" />
                  {/* Segment: In Stock */}
                  <circle
                    className="donut-segment"
                    cx="60"
                    cy="60"
                    r="50"
                    stroke="#10b981"
                    strokeDasharray={`${inStockLen} ${circ}`}
                    strokeDashoffset={inStockOffset}
                  />
                  {/* Segment: Low Stock */}
                  <circle
                    className="donut-segment"
                    cx="60"
                    cy="60"
                    r="50"
                    stroke="#f59e0b"
                    strokeDasharray={`${lowStockLen} ${circ}`}
                    strokeDashoffset={lowStockOffset}
                  />
                  {/* Segment: Out of Stock */}
                  <circle
                    className="donut-segment"
                    cx="60"
                    cy="60"
                    r="50"
                    stroke="#ef4444"
                    strokeDasharray={`${outStockLen} ${circ}`}
                    strokeDashoffset={outStockOffset}
                  />
                </svg>
                <div className="donut-label">
                  <span className="donut-label-value">{total}</span>
                  <div className="donut-label-title">Items</div>
                </div>
              </div>

              {/* Legends with Details */}
              <div className="chart-legends">
                <div className="legend-item">
                  <div className="legend-color" style={{ backgroundColor: '#10b981' }} />
                  <div className="legend-info">
                    <span className="legend-name">In Stock</span>
                    <span className="legend-value">{inStock} ({Math.round((inStock / total) * 100)}%)</span>
                  </div>
                </div>
                <div className="legend-item">
                  <div className="legend-color" style={{ backgroundColor: '#f59e0b' }} />
                  <div className="legend-info">
                    <span className="legend-name">Low Stock</span>
                    <span className="legend-value">{lowStock} ({Math.round((lowStock / total) * 100)}%)</span>
                  </div>
                </div>
                <div className="legend-item">
                  <div className="legend-color" style={{ backgroundColor: '#ef4444' }} />
                  <div className="legend-info">
                    <span className="legend-name">Out of Stock</span>
                    <span className="legend-value">{outOfStock} ({Math.round((outOfStock / total) * 100)}%)</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Low Stock Medicines Table */}
          <div className="card-container">
            <div className="card-header">
              <h2 className="card-title">Low Stock Medicines</h2>
              <span onClick={navigateToStock} className="action-link">
                View All Stock
              </span>
            </div>
            <div className="table-responsive">
              <table className="stock-table">
                <thead>
                  <tr>
                    <th>Medicine</th>
                    <th>Current Stock</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {data.lowStockMedicines.map((med) => (
                    <tr key={med.id}>
                      <td style={{ fontWeight: 600 }}>{med.name}</td>
                      <td>{med.currentStock} units</td>
                      <td>
                        <span
                          className={`badge ${
                            med.status === 'Critical' ? 'badge-critical' : 'badge-low'
                          }`}
                        >
                          {med.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column: Recent Updates + Location Status */}
        <div className="grid-column">
          {/* Recently Updated */}
          <div className="card-container">
            <div className="card-header">
              <h2 className="card-title">Recently Updated</h2>
            </div>
            <div className="updates-list">
              {data.recentUpdates.map((update) => (
                <div key={update.id} className="update-item">
                  <div className="update-indicator" />
                  <div className="update-details">
                    <span className="update-med">{update.medicineName}</span>
                    <span className="update-action">{update.action}</span>
                    <span className="update-time">{update.timestamp}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Pharmacy Location Status */}
          <div className="card-container">
            <div className="card-header">
              <h2 className="card-title">Pharmacy Location</h2>
            </div>
            <div className="location-content">
              <div className="location-icon-box">
                <svg className="location-icon-svg" viewBox="0 0 24 24">
                  <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
                </svg>
              </div>
              <div className="location-details">
                <span className="location-name">{data.locationStatus.address}</span>
                <span className="location-status">{data.locationStatus.status}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
