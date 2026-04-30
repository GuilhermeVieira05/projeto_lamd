import { Role } from '@shared/enums/Role';
import { User } from '@modules/users/entities/User.entity';

export interface CreateUserData {
  name: string;
  email: string;
  passwordHash: string;
  role: Role;
}

export interface IUserRepository {
  findByEmail(email: string): Promise<User | null>;
  findById(id: string): Promise<User | null>;
  create(data: CreateUserData): Promise<User>;
}
