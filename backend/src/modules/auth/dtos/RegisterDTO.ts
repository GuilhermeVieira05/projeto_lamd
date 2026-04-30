import { z } from 'zod';
import { Role } from '@shared/enums/Role';

export const RegisterDTO = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(6),
  role: z.nativeEnum(Role),
});

export type RegisterDTO = z.infer<typeof RegisterDTO>;
