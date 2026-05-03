import { AppError } from '@shared/errors/AppError';
import { IUserRepository } from '../repositories/IUserRepository';

export interface PublicUserProfile {
  id: string;
  name: string;
  role: string;
  createdAt: Date;
}

export class GetUserByIdUseCase {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(id: string): Promise<PublicUserProfile> {
    const user = await this.userRepository.findById(id);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    return {
      id: user.id,
      name: user.name,
      role: user.role,
      createdAt: user.createdAt,
    };
  }
}
