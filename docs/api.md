# Documentação da API — Sistema de Reserva de Serviços

Base URL: `http://localhost:3000`

Todas as rotas protegidas exigem o header:
```
Authorization: Bearer <token>
```

---

## Autenticação

### POST /auth/register

Cadastra um novo usuário. O campo `role` define se é cliente ou prestador.

**Request**
```http
POST /auth/register
Content-Type: application/json
```
```json
{
  "name": "João Silva",
  "email": "joao@email.com",
  "password": "senha123",
  "role": "CLIENT"
}
```

> Para cadastrar um prestador, use `"role": "PROVIDER"`.

**Response 201**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "name": "João Silva",
  "email": "joao@email.com",
  "role": "CLIENT",
  "created_at": "2026-05-09T10:00:00.000Z"
}
```

**Response 409** — e-mail já cadastrado
```json
{ "message": "Email already in use" }
```

---

### POST /auth/login

Autentica o usuário e retorna um JWT.

**Request**
```http
POST /auth/login
Content-Type: application/json
```
```json
{
  "email": "joao@email.com",
  "password": "senha123"
}
```

**Response 200**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "name": "João Silva",
    "email": "joao@email.com",
    "role": "CLIENT"
  }
}
```

**Response 401** — credenciais inválidas
```json
{ "message": "Invalid credentials" }
```

---

## Serviços

### POST /services

Cria um novo tipo de serviço. Apenas prestadores (`PROVIDER`) podem criar.

**Request**
```http
POST /services
Authorization: Bearer <token-de-um-provider>
Content-Type: application/json
```
```json
{
  "name": "Limpeza Residencial",
  "description": "Limpeza completa de residências até 100m²",
  "price": 150.00,
  "duration_minutes": 180
}
```

**Response 201**
```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "name": "Limpeza Residencial",
  "description": "Limpeza completa de residências até 100m²",
  "price": "150.00",
  "duration_minutes": 180,
  "active": true,
  "provider_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "created_at": "2026-05-09T10:05:00.000Z"
}
```

**Response 403** — usuário não é PROVIDER
```json
{ "message": "Forbidden" }
```

---

### GET /services/mine

Lista os serviços do **prestador autenticado** (ativos **e** inativos), do mais recente para o mais antigo. Apenas prestadores (`PROVIDER`).

**Request**
```http
GET /services/mine
Authorization: Bearer <token-de-um-provider>
```

**Response 200**
```json
[
  {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "name": "Limpeza Residencial",
    "description": "Limpeza completa de residências até 100m²",
    "price": "150.00",
    "durationMinutes": 180,
    "active": true,
    "provider": {
      "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
      "name": "Maria Prestadora"
    },
    "created_at": "2026-05-09T10:05:00.000Z"
  }
]
```

**Response 403** — usuário não é PROVIDER
```json
{ "message": "Forbidden" }
```

---

### GET /services

Lista todos os serviços disponíveis (ativos).

**Request**
```http
GET /services
Authorization: Bearer <token>
```

**Response 200**
```json
[
  {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "name": "Limpeza Residencial",
    "description": "Limpeza completa de residências até 100m²",
    "price": "150.00",
    "duration_minutes": 180,
    "active": true,
    "provider": {
      "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
      "name": "Maria Prestadora"
    },
    "created_at": "2026-05-09T10:05:00.000Z"
  }
]
```

---

### GET /services/:id

Retorna os detalhes de um serviço específico.

**Request**
```http
GET /services/b2c3d4e5-f6a7-8901-bcde-f12345678901
Authorization: Bearer <token>
```

**Response 200**
```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "name": "Limpeza Residencial",
  "description": "Limpeza completa de residências até 100m²",
  "price": "150.00",
  "duration_minutes": 180,
  "active": true,
  "provider": {
    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "name": "Maria Prestadora"
  },
  "created_at": "2026-05-09T10:05:00.000Z"
}
```

**Response 404**
```json
{ "message": "Service not found" }
```

---

### PATCH /services/:id

Atualiza um serviço existente. Apenas o prestador dono do serviço pode atualizar.

**Request**
```http
PATCH /services/b2c3d4e5-f6a7-8901-bcde-f12345678901
Authorization: Bearer <token-do-provider-dono>
Content-Type: application/json
```
```json
{
  "price": 170.00,
  "description": "Limpeza completa de residências até 120m²"
}
```

> Todos os campos são opcionais — envie apenas o que deseja alterar.

**Response 200**
```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "name": "Limpeza Residencial",
  "description": "Limpeza completa de residências até 120m²",
  "price": "170.00",
  "duration_minutes": 180,
  "active": true,
  "provider_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "created_at": "2026-05-09T10:05:00.000Z"
}
```

---

## Reservas

### POST /reservations

Cria uma nova reserva. Apenas clientes (`CLIENT`) podem criar.

A reserva **não é criada imediatamente** — o request publica um comando no RabbitMQ e retorna `202 Accepted`. A criação ocorre de forma assíncrona pelo consumer. O resultado chega via WebSocket (`reservation.created`) ou pode ser consultado em `GET /notifications`.

**Request**
```http
POST /reservations
Authorization: Bearer <token-de-um-client>
Content-Type: application/json
```
```json
{
  "serviceTypeId": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "scheduledAt": "2026-05-15T14:00:00.000Z",
  "notes": "Apartamento no 3º andar, portaria com interfone"
}
```

> `notes` é opcional.

**Response 202** — comando recebido, processamento assíncrono
```json
{ "message": "Reservation request received. You will be notified shortly." }
```

**Response 403** — usuário não é CLIENT
```json
{ "message": "Forbidden" }
```

---

### GET /reservations

Lista as reservas do usuário autenticado. CLIENTs veem suas próprias reservas; PROVIDERs veem as reservas de seus serviços.

**Request**
```http
GET /reservations
Authorization: Bearer <token>
```

**Response 200**
```json
[
  {
    "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
    "status": "PENDING",
    "scheduled_at": "2026-05-15T14:00:00.000Z",
    "notes": "Apartamento no 3º andar, portaria com interfone",
    "client": {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "name": "João Silva"
    },
    "service_type": {
      "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
      "name": "Limpeza Residencial",
      "price": "170.00"
    },
    "provider": {
      "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
      "name": "Maria Prestadora"
    },
    "created_at": "2026-05-09T10:10:00.000Z",
    "updated_at": "2026-05-09T10:10:00.000Z"
  }
]
```

---

### GET /reservations/:id

Retorna os detalhes de uma reserva. O usuário deve ser o cliente ou o prestador da reserva.

**Request**
```http
GET /reservations/d4e5f6a7-b8c9-0123-defa-234567890123
Authorization: Bearer <token>
```

**Response 200** — mesmo schema do item acima

**Response 403** — usuário sem acesso a esta reserva
```json
{ "message": "Forbidden" }
```

**Response 404**
```json
{ "message": "Reservation not found" }
```

---

### PATCH /reservations/:id/cancel

Cancela uma reserva. Disponível para `CLIENT` e `PROVIDER` com regras distintas:

- **CLIENT** — pode cancelar somente reservas com status `PENDING`
- **PROVIDER** — pode cancelar somente reservas com status `ACCEPTED`

Em ambos os casos, a outra parte é notificada via RabbitMQ → WebSocket/inbox.

**Request**
```http
PATCH /reservations/d4e5f6a7-b8c9-0123-defa-234567890123/cancel
Authorization: Bearer <token-do-client-ou-provider>
```

> Sem body.

**Response 200**
```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "status": "CANCELLED",
  "scheduledAt": "2026-05-15T14:00:00.000Z",
  "updatedAt": "2026-05-14T09:00:00.000Z"
}
```

**Response 422** — transição inválida para o role
```json
{ "message": "Cannot cancel a reservation with status ACCEPTED" }
```

**Response 403** — usuário não é dono da reserva
```json
{ "message": "Forbidden" }
```

---

### PATCH /reservations/:id/status

Atualiza o status de uma reserva. Apenas o prestador responsável pode executar.

**Transições válidas:**
- `PENDING` → `ACCEPTED` ou `REFUSED`
- `ACCEPTED` → `COMPLETED`

**Request**
```http
PATCH /reservations/d4e5f6a7-b8c9-0123-defa-234567890123/status
Authorization: Bearer <token-do-provider>
Content-Type: application/json
```
```json
{
  "status": "ACCEPTED"
}
```

**Response 200**
```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "status": "ACCEPTED",
  "scheduled_at": "2026-05-15T14:00:00.000Z",
  "notes": "Apartamento no 3º andar, portaria com interfone",
  "client": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "name": "João Silva"
  },
  "service_type": {
    "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "name": "Limpeza Residencial",
    "price": "170.00"
  },
  "provider": {
    "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
    "name": "Maria Prestadora"
  },
  "created_at": "2026-05-09T10:10:00.000Z",
  "updated_at": "2026-05-09T10:15:00.000Z"
}
```

**Response 400** — transição de status inválida
```json
{ "message": "Invalid status transition: REFUSED → ACCEPTED" }
```

**Response 403** — usuário não é o prestador desta reserva
```json
{ "message": "Forbidden" }
```

---

## Notificações

Notificações são geradas automaticamente por eventos RabbitMQ e persistidas no banco. Disponíveis para consulta mesmo que o usuário estivesse offline quando o evento ocorreu.

### GET /notifications

Lista todas as notificações do usuário autenticado, da mais recente para a mais antiga.

**Request**
```http
GET /notifications
Authorization: Bearer <token>
```

**Response 200**
```json
{
  "notifications": [
    {
      "id": "f5c5e3fc-ec89-4886-aa0f-43d0d150f400",
      "userId": "8e53ec45-4dad-4259-bd70-aa2e5ab4fefe",
      "type": "reservation.created",
      "channel": "in_app",
      "payload": {
        "reservationId": "5b43c2d1-1631-45a3-9490-7ba8927de703",
        "clientName": "João Silva",
        "serviceType": "Corte de Cabelo",
        "scheduledAt": "2026-06-01T10:00:00.000Z"
      },
      "read": false,
      "createdAt": "2026-05-20T02:53:07.230Z"
    }
  ],
  "unreadCount": 1
}
```

---

### PATCH /notifications/read-all

Marca todas as notificações do usuário autenticado como lidas.

**Request**
```http
PATCH /notifications/read-all
Authorization: Bearer <token>
```

**Response 204** — sem corpo

---

### PATCH /notifications/:id/read

Marca uma notificação específica como lida.

**Request**
```http
PATCH /notifications/f5c5e3fc-ec89-4886-aa0f-43d0d150f400/read
Authorization: Bearer <token>
```

**Response 204** — sem corpo

**Response 404**
```json
{ "message": "Notification not found" }
```

**Response 403** — notificação pertence a outro usuário
```json
{ "message": "Forbidden" }
```

---

## Códigos de Status HTTP

| Código | Significado |
|---|---|
| 200 | OK — requisição bem-sucedida |
| 201 | Created — recurso criado com sucesso |
| 400 | Bad Request — dados inválidos ou transição de status não permitida |
| 401 | Unauthorized — token ausente ou inválido |
| 403 | Forbidden — sem permissão para este recurso |
| 404 | Not Found — recurso não encontrado |
| 409 | Conflict — e-mail já cadastrado |
| 500 | Internal Server Error — erro interno do servidor |

## Status das Reservas

```
PENDING ──► ACCEPTED ──► COMPLETED
        └──► REFUSED
        └──► CANCELLED  (apenas pelo CLIENT)
```

| Status | Descrição | Quem pode acionar |
|---|---|---|
| `PENDING` | Reserva criada, aguardando resposta do prestador | — (estado inicial) |
| `ACCEPTED` | Prestador aceitou a reserva | PROVIDER |
| `REFUSED` | Prestador recusou a reserva | PROVIDER |
| `COMPLETED` | Serviço realizado e marcado como concluído | PROVIDER |
| `CANCELLED` | Reserva cancelada pelo cliente | CLIENT |
