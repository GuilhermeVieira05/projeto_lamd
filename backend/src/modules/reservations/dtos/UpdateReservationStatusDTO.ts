import { z } from 'zod';
import { ReservationStatus } from '@shared/enums/ReservationStatus';

export const UpdateReservationStatusDTO = z.object({
  status: z.enum([
    ReservationStatus.ACCEPTED,
    ReservationStatus.REFUSED,
    ReservationStatus.COMPLETED,
  ]),
});

export type UpdateReservationStatusDTO = z.infer<typeof UpdateReservationStatusDTO>;
