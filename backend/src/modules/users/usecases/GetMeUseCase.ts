import { AppError } from '@shared/errors/AppError';
import { IUserRepository } from '../repositories/IUserRepository';

export interface PrivateUserProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  createdAt: Date;
}

export class GetMeUseCase {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(id: string): Promise<PrivateUserProfile> {
    const user = await this.userRepository.findById(id);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    };
  }
}
