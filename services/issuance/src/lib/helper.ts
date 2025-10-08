import os from 'os';
import { v4 as uuidv4 } from 'uuid';
import winston from 'winston';

export const getWorkerID = (): string => {
  return process.env.WORKER_ID || os.hostname();
};

export const generateUUID = (): string => {
  return uuidv4();
};

export const createEndpointLogger = (endpoint: string, method: string) => {
  return winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    ),
    defaultMeta: { endpoint, method },
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        )
      })
    ]
  });
};