import { MigrationInterface, QueryRunner } from "typeorm";

export class AddCascadeDeleteToServiceTypes1747210000000 implements MigrationInterface {
    name = 'AddCascadeDeleteToServiceTypes1747210000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "service_types" DROP CONSTRAINT "FK_f9785883712f171fcb5f21e72a1"`);
        await queryRunner.query(`ALTER TABLE "service_types" ADD CONSTRAINT "FK_f9785883712f171fcb5f21e72a1" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "service_types" DROP CONSTRAINT "FK_f9785883712f171fcb5f21e72a1"`);
        await queryRunner.query(`ALTER TABLE "service_types" ADD CONSTRAINT "FK_f9785883712f171fcb5f21e72a1" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }
}
