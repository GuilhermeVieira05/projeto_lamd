import bcrypt from 'bcryptjs';
import { AppError } from '@shared/errors/AppError';
import { IUserRepository } from '@modules/users/repositories/IUserRepository';
import { RegisterDTO } from '../dtos/RegisterDTO';

interface RegisterResponse {
  id: string;
  name: string;
  email: string;
  role: string;
  createdAt: Date;
}

export class RegisterUseCase {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(data: RegisterDTO): Promise<RegisterResponse> {
    const existingUser = await this.userRepository.findByEmail(data.email);

    if (existingUser) {
      throw new AppError('Email already in use', 409);
    }

    const passwordHash = await bcrypt.hash(data.password, 10);

    const user = await this.userRepository.create({
      name: data.name,
      email: data.email,
      passwordHash,
      role: data.role,
    });

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      createdAt: user.createdAt,
    };
  }
}
