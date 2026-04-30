import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { AppError } from '@shared/errors/AppError';
import { IUserRepository } from '@modules/users/repositories/IUserRepository';
import { LoginDTO } from '../dtos/LoginDTO';

interface LoginResponse {
  token: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
  };
}

export class LoginUseCase {
  constructor(private readonly userRepository: IUserRepository) {}

  async execute(data: LoginDTO): Promise<LoginResponse> {
    const user = await this.userRepository.findByEmail(data.email);

    if (!user) {
      throw new AppError('Invalid credentials', 401);
    }

    const passwordMatch = await bcrypt.compare(data.password, user.passwordHash);

    if (!passwordMatch) {
      throw new AppError('Invalid credentials', 401);
    }

    const token = jwt.sign(
      { sub: user.id, role: user.role, name: user.name },
      process.env.JWT_SECRET ?? 'fallback_secret',
      { expiresIn: process.env.JWT_EXPIRES_IN ?? '7d' } as jwt.SignOptions,
    );

    return {
      token,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    };
  }
}
