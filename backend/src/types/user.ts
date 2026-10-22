export interface User {
  id: number;
  email: string;
  username: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserRow {
  id: number;
  email: string;
  username: string;
  password_hash: string;
  created_at: Date;
  updated_at: Date;
}

export interface RegisterPayload {
  email: string;
  username: string;
  password: string;
}

export interface LoginPayload {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}
