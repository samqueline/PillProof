import mongoose from 'mongoose';
import { config } from './env';

export const connectDatabase = async (): Promise<void> => {
  if (!config.mongodbUri) {
    console.warn('[Database] MONGODB_URI not provided. Skipping database connection for local/offline initialization.');
    return;
  }

  try {
    await mongoose.connect(config.mongodbUri, {
      serverSelectionTimeoutMS: 15000
    });
    console.log('[Database] Connected to MongoDB Atlas successfully.');
  } catch (error) {
    console.error('[Database] MongoDB connection error:', error);
    if (config.nodeEnv === 'production') {
      process.exit(1);
    }
  }
};

export const disconnectDatabase = async (): Promise<void> => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
    console.log('[Database] Disconnected from MongoDB.');
  }
};
