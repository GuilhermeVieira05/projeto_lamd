import { AppError } from '@shared/errors/AppError';
import { INotificationRepository } from '../repositories/INotificationRepository';
import { Notification } from '../entities/notification.entity';

export class MarkAsReadUseCase {
  constructor(private readonly notificationRepository: INotificationRepository) {}

  async execute(id: string, userId: string): Promise<Notification> {
    const notification = await this.notificationRepository.findById(id);

    if (!notification) {
      throw new AppError('Notification not found', 404);
    }

    if (notification.userId !== userId) {
      throw new AppError('Forbidden', 403);
    }

    notification.read = true;
    return this.notificationRepository.save(notification);
  }
}
