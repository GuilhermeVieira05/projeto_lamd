# Documentação de Eventos — Sistema de Reserva de Serviços

Comunicação assíncrona implementada com **RabbitMQ** usando dois padrões EIP:

- **Command Message** — `POST /reservations` publica um comando na fila; um consumer processa com controle de concorrência (prefetch 1)
- **Event Notification** — eventos de domínio são publicados após cada operação; um consumer persiste e entrega via WebSocket

---

## Infraestrutura

**Exchange:** `reservations` (type: `topic`, durable)

| Fila | Binding | Consumer | Função |
|---|---|---|---|
| `reservation.commands` | — (default exchange) | `ReservationCommandConsumer` | Processa criação de reserva serializada |
| `notification.persist` | `reservation.*`, `service.*` | `NotificationConsumer` | Persiste notificações + entrega WS |

**Management UI:** `http://localhost:15672` (admin / admin)

---

## Fluxo Geral

```
POST /reservations
    └─→ publica em reservation.commands → 202 Accepted
              ↓
    ReservationCommandConsumer (prefetch 1)
        ├── conflito? → publica reservation.conflict → cliente notificado
        └── livre?    → salva reserva → publica reservation.created
                                              ↓
                                    NotificationConsumer
                                        ├── persiste na tabela notifications
                                        └── envia WS se usuário online
```

---

## Comandos

### `reservation.commands`

Publicado por `CreateReservationUseCase` quando o cliente cria uma reserva.

**Payload:**
```json
{
  "clientId": "uuid",
  "clientName": "João Silva",
  "serviceTypeId": "uuid",
  "scheduledAt": "2026-06-01T10:00:00.000Z",
  "notes": "Opcional"
}
```

**Processamento pelo consumer:**
- Verifica se o serviço existe e está ativo
- Verifica conflito de horário (`PENDING` ou `ACCEPTED` para o mesmo serviço e horário)
- Se conflito → publica `reservation.conflict` (destino: cliente)
- Se livre → salva reserva no banco → publica `reservation.created` (destino: prestador)

---

## Eventos de Notificação

Todos os eventos abaixo são consumidos pelo `NotificationConsumer`, que:
1. Persiste na tabela `notifications` do banco
2. Envia `{ event: "notification.new", payload: <notification_row> }` via WebSocket se o usuário estiver online

---

### `reservation.created`

**Produtor:** `ReservationCommandConsumer` (após salvar a reserva)
**Destino:** Prestador (`providerId`)

```json
{
  "targetUserId": "uuid-do-prestador",
  "reservationId": "uuid",
  "clientName": "João Silva",
  "serviceType": "Corte de Cabelo",
  "scheduledAt": "2026-06-01T10:00:00.000Z"
}
```

---

### `reservation.conflict`

**Produtor:** `ReservationCommandConsumer` (quando horário já está ocupado)
**Destino:** Cliente (`clientId`)

```json
{
  "targetUserId": "uuid-do-cliente",
  "reason": "Time slot already reserved",
  "serviceType": "Corte de Cabelo",
  "scheduledAt": "2026-06-01T10:00:00.000Z"
}
```

---

### `reservation.accepted`

**Produtor:** `UpdateReservationStatusUseCase`
**Destino:** Cliente (`clientId`)

```json
{
  "targetUserId": "uuid-do-cliente",
  "reservationId": "uuid",
  "providerName": "Barbearia Silva",
  "scheduledAt": "2026-06-01T10:00:00.000Z"
}
```

---

### `reservation.refused`

**Produtor:** `UpdateReservationStatusUseCase`
**Destino:** Cliente (`clientId`)

```json
{
  "targetUserId": "uuid-do-cliente",
  "reservationId": "uuid",
  "providerName": "Barbearia Silva",
  "scheduledAt": "2026-06-01T10:00:00.000Z"
}
```

---

### `reservation.completed`

**Produtor:** `UpdateReservationStatusUseCase`
**Destino:** Cliente (`clientId`)

```json
{
  "targetUserId": "uuid-do-cliente",
  "reservationId": "uuid",
  "providerName": "Barbearia Silva",
  "scheduledAt": "2026-06-01T10:00:00.000Z",
  "completedAt": "2026-06-01T10:35:00.000Z"
}
```

---

### `reservation.cancelled`

**Produtor:** `CancelReservationUseCase` (cliente cancela uma reserva `PENDING`)
**Destino:** Prestador (`providerId`)

```json
{
  "targetUserId": "uuid-do-prestador",
  "reservationId": "uuid",
  "clientName": "João Silva",
  "serviceType": "Corte de Cabelo"
}
```

---

### `reservation.cancelled_by_provider`

**Produtor:** `CancelReservationUseCase` (prestador cancela uma reserva `ACCEPTED`)
**Destino:** Cliente (`clientId`)

```json
{
  "targetUserId": "uuid-do-cliente",
  "reservationId": "uuid",
  "providerName": "Barbearia Silva",
  "serviceType": "Corte de Cabelo"
}
```

---

### `service.deactivated`

**Produtor:** `UpdateServiceUseCase` (quando `active` muda de `true` para `false`)
**Destino:** Cada cliente com reserva `PENDING` ou `ACCEPTED` no serviço (fan-out)

> As reservas afetadas são canceladas automaticamente (`CANCELLED`).

```json
{
  "targetUserId": "uuid-do-cliente",
  "serviceId": "uuid",
  "serviceType": "Corte de Cabelo",
  "reservationId": "uuid"
}
```

---

### `service.updated`

**Produtor:** `UpdateServiceUseCase` (quando preço ou duração são alterados)
**Destino:** Cada cliente com reserva `PENDING` ou `ACCEPTED` no serviço (fan-out)

```json
{
  "targetUserId": "uuid-do-cliente",
  "serviceId": "uuid",
  "serviceType": "Corte de Cabelo",
  "reservationId": "uuid"
}
```

---

## WebSocket

Conexão: `ws://localhost:3000?token=<jwt>`

Após conectar, o servidor valida o JWT e registra o usuário. Quando uma notificação chega, o evento enviado ao cliente é:

```json
{
  "event": "notification.new",
  "payload": {
    "id": "uuid",
    "userId": "uuid",
    "type": "reservation.created",
    "channel": "in_app",
    "read": false,
    "createdAt": "2026-05-20T02:53:07.230Z",
    "payload": { "...dados do evento..." }
  }
}
```

---

## API de Notificações

Todas as rotas exigem `Authorization: Bearer <token>`.

### GET /notifications

Lista as notificações do usuário autenticado (mais recentes primeiro).

**Response 200**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "userId": "uuid",
      "type": "reservation.created",
      "channel": "in_app",
      "payload": { "..." },
      "read": false,
      "createdAt": "2026-05-20T02:53:07.230Z"
    }
  ],
  "unreadCount": 1
}
```

---

### PATCH /notifications/read-all

Marca todas as notificações do usuário como lidas.

**Response 204** — sem corpo

---

### PATCH /notifications/:id/read

Marca uma notificação específica como lida.

**Response 204** — sem corpo

**Response 404**
```json
{ "message": "Notification not found" }
```

**Response 403** — tentando marcar notificação de outro usuário
```json
{ "message": "Forbidden" }
```
