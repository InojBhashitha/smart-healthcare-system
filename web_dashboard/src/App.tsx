import React from 'react';
import { AuthProvider } from './contexts/authContext';
import { Router } from './routes/router';
import Login from './pages/Login/Login';
import Dashboard from './pages/Dashboard/Dashboard';
import Stock from './pages/Stock/Stock';
import Profile from './pages/Profile/Profile';
import Settings from './pages/Settings/Settings';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <Router
        loginPage={<Login />}
        dashboardPage={<Dashboard />}
        stockPage={<Stock />}
        profilePage={<Profile />}
        settingsPage={<Settings />}
      />
    </AuthProvider>
  );
};

export default App;
