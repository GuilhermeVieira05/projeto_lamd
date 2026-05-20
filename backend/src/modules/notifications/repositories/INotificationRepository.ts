import { Notification } from '../entities/notification.entity';

export interface CreateNotificationData {
  userId: string;
  type: string;
  channel: string;
  payload: object;
}

export interface INotificationRepository {
  create(data: CreateNotificationData): Promise<Notification>;
  findAllByUserId(userId: string): Promise<Notification[]>;
  findById(id: string): Promise<Notification | null>;
  save(notification: Notification): Promise<Notification>;
  markAllAsRead(userId: string): Promise<void>;
  countUnread(userId: string): Promise<number>;
}
