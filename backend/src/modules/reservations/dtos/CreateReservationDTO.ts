import { z } from 'zod';

export const CreateReservationDTO = z.object({
  serviceTypeId: z.string().uuid(),
  scheduledAt: z.string().datetime(),
  notes: z.string().max(500).optional(),
  clientAnswers: z.record(z.string(), z.string()).optional().default({}),
});

export type CreateReservationDTO = z.infer<typeof CreateReservationDTO>;
