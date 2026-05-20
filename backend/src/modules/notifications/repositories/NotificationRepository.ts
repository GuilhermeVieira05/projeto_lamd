import { Repository } from 'typeorm';
import { Notification } from '../entities/notification.entity';
import { CreateNotificationData, INotificationRepository } from './INotificationRepository';

export class NotificationRepository implements INotificationRepository {
  constructor(private readonly repository: Repository<Notification>) {}

  async create(data: CreateNotificationData): Promise<Notification> {
    const notification = this.repository.create(data);
    return this.repository.save(notification);
  }

  findAllByUserId(userId: string): Promise<Notification[]> {
    return this.repository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  findById(id: string): Promise<Notification | null> {
    return this.repository.findOne({ where: { id } });
  }

  save(notification: Notification): Promise<Notification> {
    return this.repository.save(notification);
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.repository.update({ userId, read: false }, { read: true });
  }

  countUnread(userId: string): Promise<number> {
    return this.repository.count({ where: { userId, read: false } });
  }
}
