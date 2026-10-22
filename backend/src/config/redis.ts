import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

// Safeguard: If the URL starts with https://, change it to rediss://
let redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
if (redisUrl.startsWith('https://')) {
  redisUrl = redisUrl.replace('https://', 'rediss://');
}

const redisClient = createClient({
  url: redisUrl
});

redisClient.on('error', (err) => {
  console.error('❌ Redis Client Error', err);
});

redisClient.on('connect', () => {
  console.log('✅ Connected to Redis');
});

export default redisClient;