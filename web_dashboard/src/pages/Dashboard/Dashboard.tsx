import React from 'react';
import { useAuth } from '../../contexts/authContext';
import './Dashboard.css';

export const Dashboard: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <div className="dashboard-container">
      <div className="dashboard-card">
        <h1 className="dashboard-title">Pharmacy Dashboard</h1>
        <p className="dashboard-subtitle">
          Welcome back, <strong>{user?.name || user?.email}</strong>
        </p>
        <button onClick={logout} className="logout-btn">
          Log Out
        </button>
      </div>
    </div>
  );
};

export default Dashboard;
