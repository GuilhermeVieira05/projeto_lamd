import { MigrationInterface, QueryRunner } from "typeorm";

export class AddClientAnswersToReservations1747230000000 implements MigrationInterface {
    name = 'AddClientAnswersToReservations1747230000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "reservations" ADD COLUMN "client_answers" jsonb NOT NULL DEFAULT '{}'`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "reservations" DROP COLUMN "client_answers"`);
    }
}
