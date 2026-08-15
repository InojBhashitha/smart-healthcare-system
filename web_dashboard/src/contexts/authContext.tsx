import React, { createContext, useContext, useState, useEffect } from 'react';
import type { LoginCredentials, AuthState } from '../types/auth';
import { authService } from '../services/authService';

interface AuthContextType extends AuthState {
  isInitializing: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const LOCAL_STORAGE_KEY = 'pharmacy_dashboard_session';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<AuthState>({
    isAuthenticated: false,
    user: null,
    token: null,
    loading: false,
    error: null,
  });
  const [isInitializing, setIsInitializing] = useState(true);

  // Hydrate state from localStorage on init
  useEffect(() => {
    try {
      const storedSession = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (storedSession) {
        const { user, token } = JSON.parse(storedSession);
        setState({
          isAuthenticated: true,
          user,
          token,
          loading: false,
          error: null,
        });
      }
    } catch (e) {
      console.error('Failed to parse stored auth session:', e);
      localStorage.removeItem(LOCAL_STORAGE_KEY);
    } finally {
      setIsInitializing(false);
    }
  }, []);

  const login = async (credentials: LoginCredentials) => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      const response = await authService.login(credentials);
      
      // Save session to localStorage
      localStorage.setItem(
        LOCAL_STORAGE_KEY,
        JSON.stringify({ user: response.user, token: response.token })
      );

      setState({
        isAuthenticated: true,
        user: response.user,
        token: response.token,
        loading: false,
        error: null,
      });
    } catch (err: any) {
      setState((prev) => ({
        ...prev,
        loading: false,
        error: err.message || 'Login failed',
      }));
      throw err;
    }
  };

  const logout = () => {
    localStorage.removeItem(LOCAL_STORAGE_KEY);
    setState({
      isAuthenticated: false,
      user: null,
      token: null,
      loading: false,
      error: null,
    });
    authService.logout().catch(console.error);
  };

  const clearError = () => {
    setState((prev) => ({ ...prev, error: null }));
  };

  return (
    <AuthContext.Provider value={{ ...state, isInitializing, login, logout, clearError }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
