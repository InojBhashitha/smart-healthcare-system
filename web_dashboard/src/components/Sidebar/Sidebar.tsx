import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/authContext';
import './Sidebar.css';

interface NavItem {
  label: string;
  hash: string;
  icon: React.ReactNode;
}

export const Sidebar: React.FC = () => {
  const { logout } = useAuth();
  const [activeHash, setActiveHash] = useState(window.location.hash || '#/dashboard');

  useEffect(() => {
    const handleHashChange = () => {
      setActiveHash(window.location.hash || '#/dashboard');
    };

    window.addEventListener('hashchange', handleHashChange);
    return () => {
      window.removeEventListener('hashchange', handleHashChange);
    };
  }, []);

  const navigateTo = (hash: string) => {
    window.location.hash = hash;
  };

  const navItems: NavItem[] = [
    {
      label: 'Dashboard',
      hash: '#/dashboard',
      icon: (
        <svg className="sidebar-icon" viewBox="0 0 24 24">
          <path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z" />
        </svg>
      ),
    },
    {
      label: 'Stock',
      hash: '#/stock',
      icon: (
        <svg className="sidebar-icon" viewBox="0 0 24 24">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z" />
        </svg>
      ),
    },
    {
      label: 'Pharmacy Profile',
      hash: '#/profile',
      icon: (
        <svg className="sidebar-icon" viewBox="0 0 24 24">
          <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 3c1.72 0 3.12 1.3 3.12 2.9S13.72 11.8 12 11.8s-3.12-1.3-3.12-2.9S10.28 6 12 6zm5 12H7v-1.1c0-2 4-3.1 5-3.1s5 1.1 5 3.1V18z" />
        </svg>
      ),
    },
    {
      label: 'Settings',
      hash: '#/settings',
      icon: (
        <svg className="sidebar-icon" viewBox="0 0 24 24">
          <path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z" />
        </svg>
      ),
    },
  ];

  return (
    <aside className="sidebar">
      {/* Branding cross SVG and Portal Name */}
      <div className="sidebar-brand">
        <svg className="sidebar-logo" viewBox="0 0 24 24">
          <path d="M19 10.5h-5.5V5c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v5.5H5c-.83 0-1.5.67-1.5 1.5s.67 1.5 1.5 1.5h5.5V19c0 .83.67 1.5 1.5 1.5s1.5-.67 1.5-1.5v-5.5H19c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5z" />
        </svg>
        <span className="sidebar-title">Smart Pharmacy</span>
      </div>

      {/* Navigation Items */}
      <nav className="sidebar-menu">
        {navItems.map((item) => (
          <button
            key={item.hash}
            onClick={() => navigateTo(item.hash)}
            className={`sidebar-item ${activeHash === item.hash ? 'active' : ''}`}
          >
            {item.icon}
            <span>{item.label}</span>
          </button>
        ))}
      </nav>

      {/* Logout separated at the bottom */}
      <div className="sidebar-footer">
        <button onClick={logout} className="sidebar-item logout-item">
          <svg className="sidebar-icon" viewBox="0 0 24 24">
            <path d="M10.09 15.59L11.5 17l5-5-5-5-1.41 1.41L12.67 11H3v2h9.67l-2.58 2.59zM19 3H5c-1.11 0-2 .9-2 2v4h2V5h14v14H5v-4H3v4c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z" />
          </svg>
          <span>Logout</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
