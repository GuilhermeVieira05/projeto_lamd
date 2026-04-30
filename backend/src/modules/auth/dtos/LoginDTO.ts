import { z } from 'zod';

export const LoginDTO = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export type LoginDTO = z.infer<typeof LoginDTO>;
