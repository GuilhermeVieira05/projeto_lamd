import { MigrationInterface, QueryRunner } from "typeorm";

export class AddRequiredFieldsToServiceTypes1747220000000 implements MigrationInterface {
    name = 'AddRequiredFieldsToServiceTypes1747220000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "service_types" ADD COLUMN "required_fields" jsonb NOT NULL DEFAULT '[]'`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "service_types" DROP COLUMN "required_fields"`);
    }
}
