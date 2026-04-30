import { z } from 'zod';

export const UpdateServiceDTO = z.object({
  name: z.string().min(2).max(100).optional(),
  description: z.string().min(10).optional(),
  price: z.number().positive().optional(),
  durationMinutes: z.number().int().positive().optional(),
  active: z.boolean().optional(),
});

export type UpdateServiceDTO = z.infer<typeof UpdateServiceDTO>;
