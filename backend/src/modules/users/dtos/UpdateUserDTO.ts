import { z } from 'zod';

export const UpdateUserDTO = z
  .object({
    name: z.string().min(2).max(100).optional(),
    email: z.string().email().optional(),
    password: z.string().min(6).optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export type UpdateUserDTO = z.infer<typeof UpdateUserDTO>;
