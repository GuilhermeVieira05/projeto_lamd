import { Repository } from 'typeorm';
import { User } from '@modules/users/entities/User.entity';
import { CreateUserData, IUserRepository, UpdateUserData } from './IUserRepository';

export class UserRepository implements IUserRepository {
  constructor(private readonly repository: Repository<User>) {}

  findByEmail(email: string): Promise<User | null> {
    return this.repository.findOneBy({ email });
  }

  findById(id: string): Promise<User | null> {
    return this.repository.findOneBy({ id });
  }

  async create(data: CreateUserData): Promise<User> {
    const user = this.repository.create(data);
    return this.repository.save(user);
  }

  async update(id: string, data: UpdateUserData): Promise<User> {
    await this.repository.update(id, data);
    return this.repository.findOneByOrFail({ id });
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }
}
