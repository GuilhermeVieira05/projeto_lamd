import { INotificationRepository } from '../repositories/INotificationRepository';
import { Notification } from '../entities/notification.entity';

interface ListNotificationsResult {
  notifications: Notification[];
  unreadCount: number;
}

export class ListNotificationsUseCase {
  constructor(private readonly notificationRepository: INotificationRepository) {}

  async execute(userId: string): Promise<ListNotificationsResult> {
    const [notifications, unreadCount] = await Promise.all([
      this.notificationRepository.findAllByUserId(userId),
      this.notificationRepository.countUnread(userId),
    ]);
    return { notifications, unreadCount };
  }
}
