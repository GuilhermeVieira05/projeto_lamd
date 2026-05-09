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

**Request**
```http
POST /reservations
Authorization: Bearer <token-de-um-client>
Content-Type: application/json
```
```json
{
  "service_type_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "scheduled_at": "2026-05-15T14:00:00.000Z",
  "notes": "Apartamento no 3º andar, portaria com interfone"
}
```

> `notes` é opcional.

**Response 201**
```json
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
```

| Status | Descrição |
|---|---|
| `PENDING` | Reserva criada, aguardando resposta do prestador |
| `ACCEPTED` | Prestador aceitou a reserva |
| `REFUSED` | Prestador recusou a reserva |
| `COMPLETED` | Serviço realizado e marcado como concluído |
