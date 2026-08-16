export interface User {
  userId: number;
  email: string;
  name: string;
  role: string;
  pharmacyId: number | null;
}

export interface AuthState {
  isAuthenticated: boolean;
  user: User | null;
  token: string | null;
  loading: boolean;
  error: string | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
}
