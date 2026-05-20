import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddCancelledStatus1747180000000 implements MigrationInterface {
  name = 'AddCancelledStatus1747180000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TYPE "public"."reservations_status_enum" ADD VALUE 'CANCELLED'`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // PostgreSQL does not support removing enum values directly.
    // Recreate the enum without CANCELLED and update the column.
    await queryRunner.query(
      `ALTER TABLE "reservations" ALTER COLUMN "status" TYPE varchar USING "status"::varchar`,
    );
    await queryRunner.query(`DROP TYPE "public"."reservations_status_enum"`);
    await queryRunner.query(
      `CREATE TYPE "public"."reservations_status_enum" AS ENUM('PENDING', 'ACCEPTED', 'REFUSED', 'COMPLETED')`,
    );
    await queryRunner.query(
      `ALTER TABLE "reservations" ALTER COLUMN "status" TYPE "public"."reservations_status_enum" USING "status"::"public"."reservations_status_enum"`,
    );
  }
}
