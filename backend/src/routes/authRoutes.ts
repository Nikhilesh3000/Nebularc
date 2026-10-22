import { Router, Request, Response } from 'express';
import {
  registerUser,
  loginUser,
  verifyToken,
} from '../services/authService';

const router = Router();

/**
 * POST /auth/register
 * Body: { email, username, password }
 */
router.post('/register', async (req: Request, res: Response) => {
  try {
    const { email, username, password } = req.body;

    if (!email || !username || !password) {
      return res.status(400).json({
        error: 'Email, username, and password are required',
      });
    }

    const result = await registerUser(email, username, password);
    res.status(201).json(result);
  } catch (err: any) {
    console.error('Register error:', err.message);
    res.status(400).json({ error: err.message || 'Registration failed' });
  }
});

/**
 * POST /auth/login
 * Body: { email, password }
 */
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const result = await loginUser(email, password);
    res.json(result);
  } catch (err: any) {
    console.error('Login error:', err.message);
    res.status(401).json({ error: err.message || 'Login failed' });
  }
});

/**
 * GET /auth/me
 * Header: Authorization: Bearer <token>
 */
router.get('/me', async (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.slice(7);
    const user = await verifyToken(token);

    if (!user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    res.json({ user });
  } catch (err: any) {
    console.error('Auth/me error:', err.message);
    res.status(401).json({ error: 'Authentication failed' });
  }
});

export default router;
