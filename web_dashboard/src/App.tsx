import React from 'react';
import { AuthProvider } from './contexts/authContext';
import { Router } from './routes/router';
import Login from './pages/Login/Login';
import Dashboard from './pages/Dashboard/Dashboard';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <Router loginPage={<Login />} dashboardPage={<Dashboard />} />
    </AuthProvider>
  );
};

export default App;
