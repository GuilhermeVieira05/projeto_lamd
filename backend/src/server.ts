import 'dotenv/config';
import { app } from './app';
import { AppDataSource } from '@infra/database';

const PORT = process.env.PORT ?? 3000;

AppDataSource.initialize()
  .then(() => {
    console.info('Database connected');
    app.listen(PORT, () => {
      console.info(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Database connection failed:', err);
    process.exit(1);
  });
