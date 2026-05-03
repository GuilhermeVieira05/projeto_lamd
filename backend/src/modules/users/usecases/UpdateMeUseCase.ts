import bcrypt from 'bcryptjs';
import { AppError } from '@shared/errors/AppError';
import { IUserRepository } from '../repositories/IUserRepository';
import { UpdateUserDTO } from '../dtos/UpdateUserDTO';

export class UpdateMeUseCase {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(id: string, dto: UpdateUserDTO) {
    if (dto.email) {
      const existing = await this.userRepository.findByEmail(dto.email);
      if (existing && existing.id !== id) {
        throw new AppError('Email already in use', 409);
      }
    }

    const updateData: { name?: string; email?: string; passwordHash?: string } = {};
    if (dto.name) updateData.name = dto.name;
    if (dto.email) updateData.email = dto.email;
    if (dto.password) updateData.passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.userRepository.update(id, updateData);

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    };
  }
}
