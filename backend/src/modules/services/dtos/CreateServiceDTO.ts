import { z } from 'zod';

export const CreateServiceDTO = z.object({
  name: z.string().min(2).max(100),
  description: z.string().min(10),
  price: z.number().positive(),
  durationMinutes: z.number().int().positive(),
});

export type CreateServiceDTO = z.infer<typeof CreateServiceDTO>;
