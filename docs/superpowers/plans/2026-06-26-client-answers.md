# Client Answers — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que o prestador defina perguntas obrigatórias ao criar um serviço, e o cliente preencha as respostas antes de confirmar a reserva.

**Architecture:** Dois campos JSONB nas tabelas existentes (`service_types.required_fields` e `reservations.client_answers`). A validação ocorre no `CreateReservationUseCase` antes de enfileirar o comando. O consumer propaga `clientAnswers` ao persistir a reserva.

**Tech Stack:** Node.js + TypeScript + TypeORM + PostgreSQL (backend); Flutter + Dart + Cupertino (mobile).

---

## Mapa de arquivos

### Backend — criados
- `backend/src/infra/database/migrations/1747220000000-AddRequiredFieldsToServiceTypes.ts`
- `backend/src/infra/database/migrations/1747230000000-AddClientAnswersToReservations.ts`

### Backend — modificados
- `backend/src/modules/services/entities/ServiceType.entity.ts` — adiciona `requiredFields: string[]`
- `backend/src/modules/services/repositories/IServiceRepository.ts` — adiciona `requiredFields` em `CreateServiceData` e `UpdateServiceData`
- `backend/src/modules/services/repositories/ServiceRepository.ts` — nenhuma mudança (TypeORM lida automaticamente)
- `backend/src/modules/services/dtos/CreateServiceDTO.ts` — adiciona `requiredFields`
- `backend/src/modules/services/dtos/UpdateServiceDTO.ts` — adiciona `requiredFields`
- `backend/src/modules/reservations/entities/Reservation.entity.ts` — adiciona `clientAnswers: Record<string, string>`
- `backend/src/modules/reservations/repositories/IReservationRepository.ts` — adiciona `clientAnswers` em `CreateReservationData`
- `backend/src/modules/reservations/dtos/CreateReservationDTO.ts` — adiciona `clientAnswers`
- `backend/src/modules/reservations/usecases/CreateReservationUseCase.ts` — valida respostas + passa `clientAnswers` no payload da fila
- `backend/src/infra/messaging/reservation.command.consumer.ts` — lê `clientAnswers` e passa para `reservationRepository.create`

### Mobile — modificados
- `mobile/lib/features/client/services/services_api.dart` — adiciona `requiredFields` em `ServiceModel`
- `mobile/lib/features/client/services/reservations_api.dart` — adiciona `clientAnswers` em `createReservation`
- `mobile/lib/features/provider/services/provider_reservations_api.dart` — adiciona `clientAnswers` em `ProviderReservationModel`
- `mobile/lib/features/provider/services/provider_services_api.dart` — adiciona `requiredFields` em `ProviderServiceModel`
- `mobile/lib/features/client/screens/service_detail_screen.dart` — seção "Informações necessárias" + coleta de respostas
- `mobile/lib/features/provider/screens/service_form_screen.dart` — seção "Informações solicitadas ao cliente" + gerência de perguntas
- `mobile/lib/features/provider/screens/reservation_detail_screen.dart` — seção "Informações do cliente"

---

## Task 1: Migration — required_fields em service_types

**Files:**
- Create: `backend/src/infra/database/migrations/1747220000000-AddRequiredFieldsToServiceTypes.ts`

- [ ] **Criar o arquivo de migration**

```typescript
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
```

- [ ] **Rodar a migration**

```bash
cd backend && npm run typeorm migration:run
```

Saída esperada: `query: ALTER TABLE "service_types" ADD COLUMN "required_fields" ...` sem erros.

- [ ] **Commit**

```bash
git add backend/src/infra/database/migrations/1747220000000-AddRequiredFieldsToServiceTypes.ts
git commit -m "feat: migration add required_fields to service_types"
```

---

## Task 2: Migration — client_answers em reservations

**Files:**
- Create: `backend/src/infra/database/migrations/1747230000000-AddClientAnswersToReservations.ts`

- [ ] **Criar o arquivo de migration**

```typescript
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
```

- [ ] **Rodar a migration**

```bash
cd backend && npm run typeorm migration:run
```

Saída esperada: `query: ALTER TABLE "reservations" ADD COLUMN "client_answers" ...` sem erros.

- [ ] **Commit**

```bash
git add backend/src/infra/database/migrations/1747230000000-AddClientAnswersToReservations.ts
git commit -m "feat: migration add client_answers to reservations"
```

---

## Task 3: Entidade ServiceType + interfaces do repositório

**Files:**
- Modify: `backend/src/modules/services/entities/ServiceType.entity.ts`
- Modify: `backend/src/modules/services/repositories/IServiceRepository.ts`

- [ ] **Adicionar campo `requiredFields` na entidade ServiceType**

Em `backend/src/modules/services/entities/ServiceType.entity.ts`, adicionar após a coluna `active`:

```typescript
  @Column({ name: 'required_fields', type: 'jsonb', default: [] })
  requiredFields: string[];
```

O arquivo completo relevante (só as colunas, manter imports e relações):
```typescript
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ name: 'provider_id', type: 'uuid' })
  providerId: string;

  @Column({ type: 'numeric', precision: 10, scale: 2 })
  price: number;

  @Column({ name: 'duration_minutes', type: 'int' })
  durationMinutes: number;

  @Column({ type: 'boolean', default: true })
  active: boolean;

  @Column({ name: 'required_fields', type: 'jsonb', default: [] })
  requiredFields: string[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
```

- [ ] **Adicionar `requiredFields` nas interfaces do repositório**

Em `backend/src/modules/services/repositories/IServiceRepository.ts`, atualizar as interfaces:

```typescript
import { ServiceType } from '@modules/services/entities/ServiceType.entity';

export interface CreateServiceData {
  name: string;
  description: string;
  providerId: string;
  price: number;
  durationMinutes: number;
  requiredFields?: string[];
}

export interface UpdateServiceData {
  name?: string;
  description?: string;
  price?: number;
  durationMinutes?: number;
  active?: boolean;
  requiredFields?: string[];
}

export interface IServiceRepository {
  findById(id: string): Promise<ServiceType | null>;
  findAllActive(): Promise<ServiceType[]>;
  findByProvider(providerId: string): Promise<ServiceType[]>;
  create(data: CreateServiceData): Promise<ServiceType>;
  update(service: ServiceType, data: UpdateServiceData): Promise<ServiceType>;
}
```

- [ ] **Verificar que o TypeScript compila**

```bash
cd backend && npx tsc --noEmit
```

Saída esperada: sem erros.

- [ ] **Commit**

```bash
git add backend/src/modules/services/entities/ServiceType.entity.ts \
        backend/src/modules/services/repositories/IServiceRepository.ts
git commit -m "feat: add requiredFields to ServiceType entity and repository interface"
```

---

## Task 4: Entidade Reservation + interfaces do repositório

**Files:**
- Modify: `backend/src/modules/reservations/entities/Reservation.entity.ts`
- Modify: `backend/src/modules/reservations/repositories/IReservationRepository.ts`

- [ ] **Adicionar campo `clientAnswers` na entidade Reservation**

Em `backend/src/modules/reservations/entities/Reservation.entity.ts`, adicionar após `notes`:

```typescript
  @Column({ name: 'client_answers', type: 'jsonb', default: {} })
  clientAnswers: Record<string, string>;
```

O arquivo completo relevante (só as colunas):
```typescript
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'client_id', type: 'uuid' })
  clientId: string;

  @Column({ name: 'service_type_id', type: 'uuid' })
  serviceTypeId: string;

  @Column({ name: 'provider_id', type: 'uuid' })
  providerId: string;

  @Column({ type: 'enum', enum: ReservationStatus, default: ReservationStatus.PENDING })
  status: ReservationStatus;

  @Column({ name: 'scheduled_at', type: 'timestamptz' })
  scheduledAt: Date;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'client_answers', type: 'jsonb', default: {} })
  clientAnswers: Record<string, string>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
```

- [ ] **Adicionar `clientAnswers` em `CreateReservationData`**

Em `backend/src/modules/reservations/repositories/IReservationRepository.ts`:

```typescript
import { Reservation } from '@modules/reservations/entities/Reservation.entity';
import { ReservationStatus } from '@shared/enums/ReservationStatus';

export interface CreateReservationData {
  clientId: string;
  serviceTypeId: string;
  providerId: string;
  scheduledAt: Date;
  notes?: string;
  clientAnswers?: Record<string, string>;
}

export interface IReservationRepository {
  findById(id: string): Promise<Reservation | null>;
  findAllByClientId(clientId: string): Promise<Reservation[]>;
  findAllByProviderId(providerId: string): Promise<Reservation[]>;
  findConflict(serviceTypeId: string, scheduledAt: Date): Promise<Reservation | null>;
  findByServiceTypeIdAndStatuses(serviceTypeId: string, statuses: ReservationStatus[]): Promise<Reservation[]>;
  create(data: CreateReservationData): Promise<Reservation>;
  save(reservation: Reservation): Promise<Reservation>;
}
```

- [ ] **Verificar que o TypeScript compila**

```bash
cd backend && npx tsc --noEmit
```

Saída esperada: sem erros.

- [ ] **Commit**

```bash
git add backend/src/modules/reservations/entities/Reservation.entity.ts \
        backend/src/modules/reservations/repositories/IReservationRepository.ts
git commit -m "feat: add clientAnswers to Reservation entity and repository interface"
```

---

## Task 5: DTOs — CreateServiceDTO, UpdateServiceDTO, CreateReservationDTO

**Files:**
- Modify: `backend/src/modules/services/dtos/CreateServiceDTO.ts`
- Modify: `backend/src/modules/services/dtos/UpdateServiceDTO.ts`
- Modify: `backend/src/modules/reservations/dtos/CreateReservationDTO.ts`

- [ ] **Atualizar CreateServiceDTO**

```typescript
import { z } from 'zod';

export const CreateServiceDTO = z.object({
  name: z.string().min(2).max(100),
  description: z.string().min(10),
  price: z.number().positive(),
  durationMinutes: z.number().int().positive(),
  requiredFields: z.array(z.string().min(1).max(200)).max(10).optional().default([]),
});

export type CreateServiceDTO = z.infer<typeof CreateServiceDTO>;
```

- [ ] **Atualizar UpdateServiceDTO**

```typescript
import { z } from 'zod';

export const UpdateServiceDTO = z.object({
  name: z.string().min(2).max(100).optional(),
  description: z.string().min(10).optional(),
  price: z.number().positive().optional(),
  durationMinutes: z.number().int().positive().optional(),
  active: z.boolean().optional(),
  requiredFields: z.array(z.string().min(1).max(200)).max(10).optional(),
});

export type UpdateServiceDTO = z.infer<typeof UpdateServiceDTO>;
```

- [ ] **Atualizar CreateReservationDTO**

```typescript
import { z } from 'zod';

export const CreateReservationDTO = z.object({
  serviceTypeId: z.string().uuid(),
  scheduledAt: z.string().datetime(),
  notes: z.string().max(500).optional(),
  clientAnswers: z.record(z.string(), z.string()).optional().default({}),
});

export type CreateReservationDTO = z.infer<typeof CreateReservationDTO>;
```

- [ ] **Verificar que o TypeScript compila**

```bash
cd backend && npx tsc --noEmit
```

Saída esperada: sem erros.

- [ ] **Commit**

```bash
git add backend/src/modules/services/dtos/CreateServiceDTO.ts \
        backend/src/modules/services/dtos/UpdateServiceDTO.ts \
        backend/src/modules/reservations/dtos/CreateReservationDTO.ts
git commit -m "feat: add requiredFields to service DTOs and clientAnswers to reservation DTO"
```

---

## Task 6: CreateReservationUseCase — validar respostas + passar no payload

**Files:**
- Modify: `backend/src/modules/reservations/usecases/CreateReservationUseCase.ts`

- [ ] **Atualizar o use case**

```typescript
import { AppError } from '@shared/errors/AppError';
import { IServiceRepository } from '@modules/services/repositories/IServiceRepository';
import { getRabbitMQChannel, QUEUE_RESERVATION_COMMANDS } from '@infra/messaging/rabbitmq.connection';
import { CreateReservationDTO } from '../dtos/CreateReservationDTO';

export class CreateReservationUseCase {
  constructor(private readonly serviceRepository: IServiceRepository) {}

  async execute(clientId: string, clientName: string, data: CreateReservationDTO): Promise<void> {
    const service = await this.serviceRepository.findById(data.serviceTypeId);

    if (!service || !service.active) {
      throw new AppError('Service not found or unavailable', 404);
    }

    const scheduledAt = new Date(data.scheduledAt);

    if (scheduledAt <= new Date()) {
      throw new AppError('Scheduled date must be in the future', 400);
    }

    if (service.requiredFields.length > 0) {
      const answers = data.clientAnswers ?? {};
      for (const question of service.requiredFields) {
        if (!answers[question] || answers[question].trim() === '') {
          throw new AppError(`Resposta obrigatória: ${question}`, 400);
        }
      }
    }

    const channel = await getRabbitMQChannel();
    channel.sendToQueue(
      QUEUE_RESERVATION_COMMANDS,
      Buffer.from(JSON.stringify({
        clientId,
        clientName,
        serviceTypeId: data.serviceTypeId,
        scheduledAt: scheduledAt.toISOString(),
        notes: data.notes,
        clientAnswers: data.clientAnswers ?? {},
      })),
      { persistent: true, contentType: 'application/json' },
    );

    console.info(`[CreateReservationUseCase] Command queued for client ${clientId}`);
  }
}
```

- [ ] **Verificar que o TypeScript compila**

```bash
cd backend && npx tsc --noEmit
```

Saída esperada: sem erros.

- [ ] **Commit**

```bash
git add backend/src/modules/reservations/usecases/CreateReservationUseCase.ts
git commit -m "feat: validate required fields answers in CreateReservationUseCase"
```

---

## Task 7: reservation.command.consumer — persistir clientAnswers

**Files:**
- Modify: `backend/src/infra/messaging/reservation.command.consumer.ts`

- [ ] **Atualizar o consumer**

```typescript
import { getCommandChannel, getRabbitMQChannel, QUEUE_RESERVATION_COMMANDS } from './rabbitmq.connection';
import { IReservationRepository } from '@modules/reservations/repositories/IReservationRepository';
import { IServiceRepository } from '@modules/services/repositories/IServiceRepository';
import { IEventPublisher } from './producer';

interface ReservationCommandPayload {
  clientId: string;
  clientName: string;
  serviceTypeId: string;
  scheduledAt: string;
  notes?: string;
  clientAnswers?: Record<string, string>;
}

export async function startReservationCommandConsumer(
  reservationRepository: IReservationRepository,
  serviceRepository: IServiceRepository,
  eventPublisher: IEventPublisher,
): Promise<void> {
  const channel = await getCommandChannel();

  await channel.consume(QUEUE_RESERVATION_COMMANDS, async (msg) => {
    if (!msg) return;

    try {
      const payload = JSON.parse(msg.content.toString()) as ReservationCommandPayload;
      const { clientId, clientName, serviceTypeId, scheduledAt, notes, clientAnswers } = payload;

      const service = await serviceRepository.findById(serviceTypeId);

      if (!service || !service.active) {
        await eventPublisher.publish('reservation.conflict', {
          targetUserId: clientId,
          reason: 'Service not found or unavailable',
        });
        channel.ack(msg);
        return;
      }

      const scheduledDate = new Date(scheduledAt);
      const conflict = await reservationRepository.findConflict(serviceTypeId, scheduledDate);

      if (conflict) {
        await eventPublisher.publish('reservation.conflict', {
          targetUserId: clientId,
          reason: 'Time slot already reserved',
          serviceType: service.name,
          scheduledAt,
        });
        console.info(`[CommandConsumer] Conflict for service ${serviceTypeId} at ${scheduledAt}`);
        channel.ack(msg);
        return;
      }

      const reservation = await reservationRepository.create({
        clientId,
        serviceTypeId: service.id,
        providerId: service.providerId,
        scheduledAt: scheduledDate,
        notes,
        clientAnswers: clientAnswers ?? {},
      });

      await eventPublisher.publish('reservation.created', {
        targetUserId: service.providerId,
        reservationId: reservation.id,
        clientName,
        serviceType: service.name,
        scheduledAt: reservation.scheduledAt,
      });

      console.info(`[CommandConsumer] Reservation ${reservation.id} created for client ${clientId}`);
      channel.ack(msg);
    } catch (err) {
      console.error('[CommandConsumer] Failed to process command:', err);
      channel.nack(msg, false, true);
    }
  });

  console.info(`[CommandConsumer] Listening on queue "${QUEUE_RESERVATION_COMMANDS}" (prefetch 1).`);
}
```

- [ ] **Verificar que o TypeScript compila**

```bash
cd backend && npx tsc --noEmit
```

Saída esperada: sem erros.

- [ ] **Testar o backend manualmente**

Subir o backend: `cd backend && npm run dev`

1. Criar um serviço com `requiredFields`:
```bash
curl -s -X POST http://localhost:3000/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_PROVIDER>" \
  -d '{"name":"Banho e Tosa","description":"Serviço completo para pets","price":80,"durationMinutes":60,"requiredFields":["Quantos pets serão?","Qual a raça?"]}' | jq .
```
Esperado: objeto de serviço com `requiredFields: ["Quantos pets serão?","Qual a raça?"]`.

2. Tentar criar reserva sem respostas:
```bash
curl -s -X POST http://localhost:3000/reservations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_CLIENT>" \
  -d '{"serviceTypeId":"<ID>","scheduledAt":"2026-08-01T10:00:00.000Z"}' | jq .
```
Esperado: `400` com `"message": "Resposta obrigatória: Quantos pets serão?"`.

3. Criar reserva com respostas:
```bash
curl -s -X POST http://localhost:3000/reservations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_CLIENT>" \
  -d '{"serviceTypeId":"<ID>","scheduledAt":"2026-08-01T10:00:00.000Z","clientAnswers":{"Quantos pets serão?":"2","Qual a raça?":"Labrador"}}' | jq .
```
Esperado: `201` sem body de erro.

- [ ] **Commit**

```bash
git add backend/src/infra/messaging/reservation.command.consumer.ts
git commit -m "feat: persist clientAnswers in reservation command consumer"
```

---

## Task 8: Flutter — ServiceModel com requiredFields

**Files:**
- Modify: `mobile/lib/features/client/services/services_api.dart`

- [ ] **Adicionar `requiredFields` ao `ServiceModel`**

```dart
import '../../../core/network/http_client.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String providerName;
  final List<String> requiredFields;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.providerName,
    this.requiredFields = const [],
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] as Map<String, dynamic>?;
    final fields = json['requiredFields'] as List<dynamic>?;
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: double.parse(json['price'].toString()),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      providerName: provider?['name'] as String? ?? '',
      requiredFields: fields?.map((e) => e as String).toList() ?? [],
    );
  }
}

class ServicesApi {
  final HttpClient _http;

  ServicesApi({required HttpClient http}) : _http = http;

  Future<List<ServiceModel>> listServices() async {
    final response = await _http.get('/services');
    final data = response.data as List<dynamic>;
    return data.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServiceModel> getService(String id) async {
    final response = await _http.get('/services/$id');
    return ServiceModel.fromJson(response.data as Map<String, dynamic>);
  }
}
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: `BUILD SUCCESSFUL` ou apenas warnings, sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/client/services/services_api.dart
git commit -m "feat: add requiredFields to ServiceModel"
```

---

## Task 9: Flutter — ProviderReservationModel com clientAnswers

**Files:**
- Modify: `mobile/lib/features/provider/services/provider_reservations_api.dart`

- [ ] **Adicionar `clientAnswers` ao `ProviderReservationModel`**

```dart
import '../../../core/network/http_client.dart';

class ProviderReservationModel {
  final String id;
  final String serviceTypeName;
  final String clientName;
  final String status;
  final DateTime scheduledAt;
  final String? notes;
  final bool isNew;
  final Map<String, String> clientAnswers;

  const ProviderReservationModel({
    required this.id,
    required this.serviceTypeName,
    required this.clientName,
    required this.status,
    required this.scheduledAt,
    this.notes,
    this.isNew = false,
    this.clientAnswers = const {},
  });

  ProviderReservationModel copyWith({String? status, bool? isNew}) =>
      ProviderReservationModel(
        id: id,
        serviceTypeName: serviceTypeName,
        clientName: clientName,
        status: status ?? this.status,
        scheduledAt: scheduledAt,
        notes: notes,
        isNew: isNew ?? this.isNew,
        clientAnswers: clientAnswers,
      );

  factory ProviderReservationModel.fromJson(Map<String, dynamic> json) {
    final serviceType = json['serviceType'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final answers = json['clientAnswers'] as Map<String, dynamic>?;
    return ProviderReservationModel(
      id: json['id'] as String,
      serviceTypeName: serviceType?['name'] as String? ?? '',
      clientName: client?['name'] as String? ?? '',
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      notes: json['notes'] as String?,
      clientAnswers: answers?.map((k, v) => MapEntry(k, v as String)) ?? {},
    );
  }
}

class ProviderReservationsApi {
  final HttpClient _http;

  ProviderReservationsApi({required HttpClient http}) : _http = http;

  Future<List<ProviderReservationModel>> listAll() async {
    final response = await _http.get('/reservations');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ProviderReservationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProviderReservationModel> getById(String id) async {
    final response = await _http.get('/reservations/$id');
    return ProviderReservationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, String status) async {
    await _http.patch('/reservations/$id/status', data: {'status': status});
  }
}
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/provider/services/provider_reservations_api.dart
git commit -m "feat: add clientAnswers to ProviderReservationModel"
```

---

## Task 10: Flutter — ReservationsApi aceita clientAnswers

**Files:**
- Modify: `mobile/lib/features/client/services/reservations_api.dart`

- [ ] **Atualizar `createReservation` para aceitar `clientAnswers`**

```dart
import '../../../core/network/http_client.dart';

class ReservationModel {
  final String id;
  final String serviceTypeName;
  final String providerName;
  final String status;
  final DateTime scheduledAt;
  final String? notes;

  ReservationModel({
    required this.id,
    required this.serviceTypeName,
    required this.providerName,
    required this.status,
    required this.scheduledAt,
    this.notes,
  });

  ReservationModel copyWith({String? status}) => ReservationModel(
    id: id,
    serviceTypeName: serviceTypeName,
    providerName: providerName,
    status: status ?? this.status,
    scheduledAt: scheduledAt,
    notes: notes,
  );

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final serviceType = json['serviceType'] as Map<String, dynamic>?;
    final provider = json['provider'] as Map<String, dynamic>?;
    return ReservationModel(
      id: json['id'] as String,
      serviceTypeName: serviceType?['name'] as String? ?? '',
      providerName: provider?['name'] as String? ?? '',
      status: json['status'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class ReservationsApi {
  final HttpClient _http;

  ReservationsApi({required HttpClient http}) : _http = http;

  Future<List<ReservationModel>> listReservations() async {
    final response = await _http.get('/reservations');
    final data = response.data as List<dynamic>;
    return data.map((e) => ReservationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createReservation({
    required String serviceTypeId,
    required DateTime scheduledAt,
    String? notes,
    Map<String, String> clientAnswers = const {},
  }) async {
    await _http.post('/reservations', data: {
      'serviceTypeId': serviceTypeId,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
      if (clientAnswers.isNotEmpty) 'clientAnswers': clientAnswers,
    });
  }
}
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/client/services/reservations_api.dart
git commit -m "feat: add clientAnswers param to ReservationsApi.createReservation"
```

---

## Task 11: Flutter — ServiceFormScreen com gerência de perguntas

**Files:**
- Modify: `mobile/lib/features/provider/screens/service_form_screen.dart`

- [ ] **Adicionar estado de perguntas e seção no formulário**

No topo do `_ServiceFormScreenState`, adicionar controller e lista de perguntas:

```dart
  late final TextEditingController _newQuestionController;
  late List<String> _requiredFields;
```

Em `initState`, inicializar após os outros controllers:

```dart
    _newQuestionController = TextEditingController();
    _requiredFields = List<String>.from(s?.requiredFields ?? []);
```

Em `dispose`, adicionar:

```dart
    _newQuestionController.dispose();
```

Atualizar `_save` para incluir `requiredFields` em `provider.create` e `provider.update`. No bloco `if (widget.isEditing)`:

```dart
        await provider.update(
          widget.service!.id,
          name: name,
          description: description,
          price: price,
          durationMinutes: duration,
          requiredFields: _requiredFields,
        );
```

No bloco `else`:

```dart
        await provider.create(
          name: name,
          description: description,
          price: price,
          durationMinutes: duration,
          requiredFields: _requiredFields,
        );
```

No `build`, adicionar a seção de perguntas após o campo duração e antes da mensagem de erro. Inserir logo após o campo `_durationController`:

```dart
              const SizedBox(height: 24),
              const _FieldLabel('Informações solicitadas ao cliente'),
              if (_requiredFields.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._requiredFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c2c2e),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(color: CupertinoColors.white, fontSize: 15),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 0,
                            child: const Icon(CupertinoIcons.minus_circle, color: Color(0xFFFF3B30), size: 20),
                            onPressed: () => setState(() => _requiredFields.removeAt(index)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              if (_requiredFields.length < 10) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _newQuestionController,
                        placeholder: 'Ex.: Quantos pets serão?',
                        style: const TextStyle(color: CupertinoColors.white),
                        placeholderStyle: const TextStyle(color: Color(0xFF636366)),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2c2c2e),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        final q = _newQuestionController.text.trim();
                        if (q.isNotEmpty) {
                          setState(() {
                            _requiredFields.add(q);
                            _newQuestionController.clear();
                          });
                        }
                      },
                      child: const Text('Adicionar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/provider/screens/service_form_screen.dart
git commit -m "feat: add required fields management to ServiceFormScreen"
```

---

## Task 12: Flutter — ServiceDetailScreen coleta respostas do cliente

**Files:**
- Modify: `mobile/lib/features/client/screens/service_detail_screen.dart`

- [ ] **Adicionar estado de respostas e validação**

No topo de `_ServiceDetailScreenState`, adicionar:

```dart
  final Map<String, TextEditingController> _answerControllers = {};
```

Após `setState(() { _service = service; _isLoading = false; })` em `_loadService`, inicializar os controllers:

```dart
      if (mounted) {
        setState(() { _service = service; _isLoading = false; });
        for (final q in service.requiredFields) {
          _answerControllers[q] = TextEditingController();
        }
      }
```

Em `dispose`, adicionar:

```dart
    for (final c in _answerControllers.values) {
      c.dispose();
    }
```

Atualizar `_book` para coletar respostas e passar no `createReservation`:

```dart
  Future<void> _book() async {
    final answers = {
      for (final entry in _answerControllers.entries)
        entry.key: entry.value.text.trim()
    };
    setState(() { _isBooking = true; });
    try {
      await _reservationsApi.createReservation(
        serviceTypeId: widget.serviceId,
        scheduledAt: _selectedDate,
        clientAnswers: answers,
      );
      // ... resto do método igual
```

Adicionar getter para saber se todas as respostas foram preenchidas (para desabilitar o botão):

```dart
  bool get _allAnswered =>
      _answerControllers.isEmpty ||
      _answerControllers.values.every((c) => c.text.trim().isNotEmpty);
```

No `build`, adicionar a seção de respostas. Dentro do `Column` do `SingleChildScrollView`, inserir após o `_Section` do prestador e antes do `SizedBox(height: 32)` que precede o botão:

```dart
              if (_service!.requiredFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Informações necessárias',
                  child: Column(
                    children: _service!.requiredFields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _service!.requiredFields.length - 1 ? 12 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF8e8e93), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            StatefulBuilder(
                              builder: (context, setInner) => CupertinoTextField(
                                controller: _answerControllers[question],
                                placeholder: 'Sua resposta',
                                style: const TextStyle(color: CupertinoColors.white),
                                placeholderStyle: const TextStyle(color: Color(0xFF636366)),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3a3a3c),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
```

Atualizar o `onPressed` do botão "Confirmar Reserva" para usar `_allAnswered`:

```dart
                  onPressed: (_isBooking || !_allAnswered) ? null : _book,
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/client/screens/service_detail_screen.dart
git commit -m "feat: collect client answers in ServiceDetailScreen"
```

---

## Task 13: Flutter — ReservationDetailScreen exibe clientAnswers

**Files:**
- Modify: `mobile/lib/features/provider/screens/reservation_detail_screen.dart`

- [ ] **Adicionar seção "Informações do cliente" no build**

No `build` do `ReservationDetailScreen`, dentro do `_SectionCard` existente, após o bloco de `notes` (linha `if (_reservation.notes != null && _reservation.notes!.isNotEmpty)`), adicionar:

```dart
                  if (_reservation.clientAnswers.isNotEmpty) ...[
                    const _Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMAÇÕES DO CLIENTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF636366),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._reservation.clientAnswers.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(CupertinoIcons.chat_bubble_text_fill, size: 16, color: Color(0xFF636366)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF8e8e93), fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.value,
                                        style: const TextStyle(fontSize: 15, color: CupertinoColors.white, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/provider/screens/reservation_detail_screen.dart
git commit -m "feat: show client answers in ReservationDetailScreen"
```

---

## Task 14: Atualizar ProviderServiceModel com requiredFields

**Files:**
- Modify: `mobile/lib/features/provider/services/provider_services_api.dart`

> Esta task garante que o `ServiceFormScreen` receba `requiredFields` ao editar um serviço existente.

- [ ] **Verificar o `ProviderServiceModel` atual**

Ler o arquivo `mobile/lib/features/provider/services/provider_services_api.dart` e verificar se `ProviderServiceModel` tem o campo `requiredFields`. Se não tiver, adicionar seguindo o mesmo padrão do `ServiceModel`.

- [ ] **Adicionar `requiredFields` ao `ProviderServiceModel`**

Adicionar o campo na classe e no `fromJson`, seguindo o mesmo padrão da Task 8:

```dart
  final List<String> requiredFields;
```

No construtor, adicionar:
```dart
    this.requiredFields = const [],
```

No `fromJson`, adicionar antes do `return`:
```dart
    final fields = json['requiredFields'] as List<dynamic>?;
```

E no `return`:
```dart
      requiredFields: fields?.map((e) => e as String).toList() ?? [],
```

- [ ] **Verificar que o Flutter compila**

```bash
cd mobile && flutter build apk --debug 2>&1 | tail -5
```

Saída esperada: sem erros de compilação.

- [ ] **Commit**

```bash
git add mobile/lib/features/provider/services/provider_services_api.dart
git commit -m "feat: add requiredFields to ProviderServiceModel"
```

---

## Task 15: Teste ponta a ponta

- [ ] **Subir o ambiente completo**

```bash
# Terminal 1 — backend
cd backend && npm run dev

# Terminal 2 — mobile
cd mobile && flutter run
```

- [ ] **Fluxo de teste**

1. Logar como **PROVIDER** no app
2. Criar um novo serviço com 2 perguntas: "Quantos pets serão?" e "Qual a raça?"
3. Verificar que as perguntas aparecem salvas ao reabrir o serviço para editar
4. Logar como **CLIENT** no app
5. Abrir o serviço criado — verificar que aparecem os campos de resposta obrigatórios
6. Tentar confirmar sem preencher — botão deve estar desabilitado
7. Preencher as respostas e confirmar — reserva deve ser criada
8. Logar como **PROVIDER** novamente
9. Abrir a reserva recebida — verificar que as respostas aparecem em "Informações do cliente"
10. Aceitar a reserva

- [ ] **Commit final se necessário**

```bash
git add -A
git commit -m "feat: client answers integration complete"
```
