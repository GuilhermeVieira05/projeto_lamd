import { MigrationInterface, QueryRunner } from "typeorm";

export class AddCascadeDeleteToReservations1747200000000 implements MigrationInterface {
    name = 'AddCascadeDeleteToReservations1747200000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_eb7027e899ba8bd29f5bee39531"`);
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_12e918a62aff6eb6b4aba770cdc"`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_eb7027e899ba8bd29f5bee39531" FOREIGN KEY ("client_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_12e918a62aff6eb6b4aba770cdc" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_eb7027e899ba8bd29f5bee39531"`);
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_12e918a62aff6eb6b4aba770cdc"`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_eb7027e899ba8bd29f5bee39531" FOREIGN KEY ("client_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_12e918a62aff6eb6b4aba770cdc" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }
}
