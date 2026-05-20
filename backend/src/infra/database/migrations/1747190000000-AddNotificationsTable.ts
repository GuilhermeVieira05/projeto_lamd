import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddNotificationsTable1747190000000 implements MigrationInterface {
  name = 'AddNotificationsTable1747190000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE "notifications" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "type" character varying(64) NOT NULL,
        "channel" character varying(32) NOT NULL DEFAULT 'in_app',
        "payload" jsonb NOT NULL,
        "read" boolean NOT NULL DEFAULT false,
        "created_at" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_notifications" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(`
      ALTER TABLE "notifications"
      ADD CONSTRAINT "FK_notifications_user_id"
      FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
    `);
    await queryRunner.query(`CREATE INDEX "idx_notifications_user_id" ON "notifications" ("user_id")`);
    await queryRunner.query(`CREATE INDEX "idx_notifications_user_read" ON "notifications" ("user_id", "read")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "idx_notifications_user_read"`);
    await queryRunner.query(`DROP INDEX "idx_notifications_user_id"`);
    await queryRunner.query(`ALTER TABLE "notifications" DROP CONSTRAINT "FK_notifications_user_id"`);
    await queryRunner.query(`DROP TABLE "notifications"`);
  }
}
