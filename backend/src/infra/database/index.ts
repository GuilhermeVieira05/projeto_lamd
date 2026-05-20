import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL?.includes('localhost') ? false : { rejectUnauthorized: false },
  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
  entities: [__dirname + '/../../modules/**/entities/*.entity{.ts,.js}'],
  migrations: [__dirname + '/migrations/*{.ts,.js}'],
});
