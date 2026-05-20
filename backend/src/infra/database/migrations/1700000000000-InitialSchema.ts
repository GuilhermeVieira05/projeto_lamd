import { MigrationInterface, QueryRunner } from "typeorm";

export class InitialSchema1700000000000 implements MigrationInterface {
    name = 'InitialSchema1700000000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."reservations_status_enum" AS ENUM('PENDING', 'ACCEPTED', 'REFUSED', 'COMPLETED')`);
        await queryRunner.query(`CREATE TABLE "reservations" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "client_id" uuid NOT NULL, "service_type_id" uuid NOT NULL, "provider_id" uuid NOT NULL, "status" "public"."reservations_status_enum" NOT NULL DEFAULT 'PENDING', "scheduled_at" TIMESTAMP WITH TIME ZONE NOT NULL, "notes" text, "created_at" TIMESTAMP NOT NULL DEFAULT now(), "updated_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_da95cef71b617ac35dc5bcda243" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "service_types" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "name" character varying(100) NOT NULL, "description" text NOT NULL, "provider_id" uuid NOT NULL, "price" numeric(10,2) NOT NULL, "duration_minutes" integer NOT NULL, "active" boolean NOT NULL DEFAULT true, "created_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_1dc93417a097cdee3491f39d7cc" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."users_role_enum" AS ENUM('CLIENT', 'PROVIDER')`);
        await queryRunner.query(`CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "name" character varying(100) NOT NULL, "email" character varying(150) NOT NULL, "password_hash" character varying NOT NULL, "role" "public"."users_role_enum" NOT NULL, "created_at" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "UQ_97672ac88f789774dd47f7c8be3" UNIQUE ("email"), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_eb7027e899ba8bd29f5bee39531" FOREIGN KEY ("client_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_12e918a62aff6eb6b4aba770cdc" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "reservations" ADD CONSTRAINT "FK_66ee3701d75309b254e063dcb49" FOREIGN KEY ("service_type_id") REFERENCES "service_types"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "service_types" ADD CONSTRAINT "FK_f9785883712f171fcb5f21e72a1" FOREIGN KEY ("provider_id") REFERENCES "users"("id") ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "service_types" DROP CONSTRAINT "FK_f9785883712f171fcb5f21e72a1"`);
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_66ee3701d75309b254e063dcb49"`);
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_12e918a62aff6eb6b4aba770cdc"`);
        await queryRunner.query(`ALTER TABLE "reservations" DROP CONSTRAINT "FK_eb7027e899ba8bd29f5bee39531"`);
        await queryRunner.query(`DROP TABLE "users"`);
        await queryRunner.query(`DROP TYPE "public"."users_role_enum"`);
        await queryRunner.query(`DROP TABLE "service_types"`);
        await queryRunner.query(`DROP TABLE "reservations"`);
        await queryRunner.query(`DROP TYPE "public"."reservations_status_enum"`);
    }

}
