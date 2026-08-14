import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/authContext';

export type RoutePath = '#/login' | '#/dashboard';

/**
 * Gets the current location hash, defaulting to #/login
 */
export const getHashPath = (): RoutePath => {
  const hash = window.location.hash;
  if (hash === '#/dashboard' || hash === '#/login') {
    return hash as RoutePath;
  }
  return '#/login';
};

/**
 * Custom hook to navigate to a specific path
 */
export const useNavigate = () => {
  return (path: RoutePath) => {
    window.location.hash = path;
  };
};

interface RouterProps {
  loginPage: React.ReactElement;
  dashboardPage: React.ReactElement;
}

/**
 * Custom lightweight router to handle routing and route protection.
 * Listens to window hashchange events and checks authentication state.
 */
export const Router: React.FC<RouterProps> = ({ loginPage, dashboardPage }) => {
  const { isAuthenticated, isInitializing } = useAuth();
  const [currentHash, setCurrentHash] = useState<RoutePath>(getHashPath());

  useEffect(() => {
    const handleHashChange = () => {
      setCurrentHash(getHashPath());
    };

    window.addEventListener('hashchange', handleHashChange);
    return () => {
      window.removeEventListener('hashchange', handleHashChange);
    };
  }, []);

  // Sync auth state with hash routing
  useEffect(() => {
    if (isInitializing) return;

    if (isAuthenticated && currentHash !== '#/dashboard') {
      window.location.hash = '#/dashboard';
    } else if (!isAuthenticated && currentHash !== '#/login') {
      window.location.hash = '#/login';
    }
  }, [isAuthenticated, currentHash, isInitializing]);

  if (isInitializing) {
    return (
      <div style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        fontFamily: 'sans-serif',
        color: '#0d6efd'
      }}>
        <div>Loading session...</div>
      </div>
    );
  }

  // Render correct component based on path
  if (currentHash === '#/dashboard' && isAuthenticated) {
    return dashboardPage;
  }

  // Default fallback/unauthenticated page
  return loginPage;
};
