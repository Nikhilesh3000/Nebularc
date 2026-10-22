import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../config/db';
import { User, UserRow, AuthResponse } from '../types/user';

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';
const JWT_EXPIRES_IN = '30d';
const SALT_ROUNDS = 10;

// ============================================================================
// Helpers
// ============================================================================

function rowToUser(row: UserRow): User {
  return {
    id: row.id,
    email: row.email,
    username: row.username,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function generateToken(user: User): string {
  return jwt.sign(
    { userId: user.id, email: user.email, username: user.username },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

// ============================================================================
// Validation
// ============================================================================

export function validateEmail(email: string): boolean {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

export function validateUsername(username: string): boolean {
  // 3-30 chars, letters + numbers + underscore
  const re = /^[a-zA-Z0-9_]{3,30}$/;
  return re.test(username);
}

export function validatePassword(password: string): boolean {
  return password.length >= 6;
}

// ============================================================================
// Auth operations
// ============================================================================

export async function registerUser(
  email: string,
  username: string,
  password: string
): Promise<AuthResponse> {
  const normalizedEmail = email.toLowerCase().trim();
  const trimmedUsername = username.trim();

  // Validate
  if (!validateEmail(normalizedEmail)) {
    throw new Error('Invalid email format');
  }
  if (!validateUsername(trimmedUsername)) {
    throw new Error(
      'Username must be 3-30 characters (letters, numbers, underscore)'
    );
  }
  if (!validatePassword(password)) {
    throw new Error('Password must be at least 6 characters');
  }

  // Check for existing user
  const existing = await pool.query(
    `SELECT id FROM users WHERE email = $1 OR username = $2`,
    [normalizedEmail, trimmedUsername]
  );
  if (existing.rows.length > 0) {
    throw new Error('Email or username already taken');
  }

  // Hash password
  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  // Insert
  const result = await pool.query(
    `INSERT INTO users (email, username, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id, email, username, created_at, updated_at`,
    [normalizedEmail, trimmedUsername, passwordHash]
  );

  const user = rowToUser(result.rows[0] as UserRow);
  const token = generateToken(user);

  return { token, user };
}

export async function loginUser(
  email: string,
  password: string
): Promise<AuthResponse> {
  const normalizedEmail = email.toLowerCase().trim();

  // Find user
  const result = await pool.query(
    `SELECT * FROM users WHERE email = $1`,
    [normalizedEmail]
  );

  if (result.rows.length === 0) {
    throw new Error('Invalid email or password');
  }

  const row = result.rows[0] as UserRow;

  // Verify password
  const valid = await bcrypt.compare(password, row.password_hash);
  if (!valid) {
    throw new Error('Invalid email or password');
  }

  const user = rowToUser(row);
  const token = generateToken(user);

  return { token, user };
}

export async function verifyToken(token: string): Promise<User | null> {
  try {
    const payload = jwt.verify(token, JWT_SECRET) as { userId: number };
    const result = await pool.query(
      `SELECT id, email, username, created_at, updated_at
       FROM users WHERE id = $1`,
      [payload.userId]
    );
    if (result.rows.length === 0) return null;
    return rowToUser(result.rows[0] as UserRow);
  } catch {
    return null;
  }
}