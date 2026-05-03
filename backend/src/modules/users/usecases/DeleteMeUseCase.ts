import { AppError } from '@shared/errors/AppError';
import { IUserRepository } from '../repositories/IUserRepository';

export class DeleteMeUseCase {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(id: string): Promise<void> {
    const user = await this.userRepository.findById(id);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    await this.userRepository.delete(id);
  }
}
