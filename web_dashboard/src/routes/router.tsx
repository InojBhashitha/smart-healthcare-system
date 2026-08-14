import React, { useState, useEffect } from 'react';
import { useAuth } from '../contexts/authContext';
import AppLayout from '../layouts/AppLayout';

export type RoutePath = '#/login' | '#/dashboard' | '#/stock' | '#/profile' | '#/settings';

/**
 * Gets the current location hash, defaulting to #/login
 */
export const getHashPath = (): RoutePath => {
  const hash = window.location.hash;
  const validPaths: RoutePath[] = ['#/login', '#/dashboard', '#/stock', '#/profile', '#/settings'];
  if (validPaths.includes(hash as RoutePath)) {
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
  stockPage: React.ReactElement;
  profilePage: React.ReactElement;
  settingsPage: React.ReactElement;
}

/**
 * Custom lightweight router to handle routing and route protection.
 * Listens to window hashchange events and checks authentication state.
 */
export const Router: React.FC<RouterProps> = ({
  loginPage,
  dashboardPage,
  stockPage,
  profilePage,
  settingsPage,
}) => {
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

    const authenticatedPaths: RoutePath[] = ['#/dashboard', '#/stock', '#/profile', '#/settings'];

    if (isAuthenticated) {
      if (!authenticatedPaths.includes(currentHash)) {
        window.location.hash = '#/dashboard';
      }
    } else {
      if (currentHash !== '#/login') {
        window.location.hash = '#/login';
      }
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
  if (isAuthenticated) {
    let activePage = dashboardPage;
    if (currentHash === '#/stock') {
      activePage = stockPage;
    } else if (currentHash === '#/profile') {
      activePage = profilePage;
    } else if (currentHash === '#/settings') {
      activePage = settingsPage;
    }

    return <AppLayout>{activePage}</AppLayout>;
  }

  // Default fallback/unauthenticated page
  return loginPage;
};
