import { Router } from 'express';
import { authMiddleware } from '@shared/middlewares/authMiddleware';
import { UserController } from './user.controller';

const userRoutes = Router();
const controller = new UserController();

userRoutes.use(authMiddleware);

userRoutes.get('/me', controller.getMe.bind(controller));
userRoutes.get('/:id', controller.getById.bind(controller));
userRoutes.patch('/me', controller.updateMe.bind(controller));
userRoutes.delete('/me', controller.deleteMe.bind(controller));

export { userRoutes };
