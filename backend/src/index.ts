import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import redisClient from './config/redis';   // ← MUST BE HERE
import pool from './config/db';             // ← MUST BE HERE
import { registerRoomHandlers } from './sockets/roomHandler';
import authRoutes from './routes/authRoutes';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*' },
});

// Connect to Redis and PostgreSQL on startup
redisClient.connect().catch(console.error);
pool.query('SELECT NOW()').catch((err) => console.error('PG error:', err));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    app: 'Nebularc',
    timestamp: new Date().toISOString()
  });
});

app.use('/auth', authRoutes);

// WebSocket connection
io.on('connection', (socket) => {
  console.log('✅ User connected:', socket.id); 
  registerRoomHandlers(io, socket);
  socket.on('disconnect', () => {
    console.log('❌ User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
httpServer.listen(PORT,'0.0.0.0', () => {
  console.log(`🚀 Nebularc backend running on http://localhost:${PORT}`);
  console.log(`🔌 WebSocket ready for connections`);
});