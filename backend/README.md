# Backend — Sistema de Reserva de Serviços

API REST em **Node.js + Express + TypeScript** com **TypeORM** (PostgreSQL), mensageria assíncrona via **RabbitMQ** e entrega de notificações em tempo real via **WebSocket**. Organizada em módulos seguindo princípios de Clean Architecture (Controller → UseCase → Repository).

> Para a visão geral do projeto (mobile + backend + infra), consulte o [`README.md` na raiz](../README.md). Para a documentação completa de endpoints, veja [`docs/api.md`](../docs/api.md) e a [coleção Postman](../docs/postman-collection.json).

---

## Stack

| Camada | Tecnologia |
|---|---|
| Runtime | Node.js 20+ |
| Framework | Express 4 |
| Linguagem | TypeScript 5 |
| ORM | TypeORM 0.3 |
| Banco | PostgreSQL |
| Mensageria | RabbitMQ (`amqplib`) |
| Real-time | WebSocket (`ws`) |
| Auth | JWT (`jsonwebtoken`) + `bcryptjs` |
| Validação | Zod |

---

## Estrutura

```
backend/src/
├── server.ts                 # bootstrap: conecta DB, sobe HTTP+WS, inicia consumers
├── app.ts                    # Express app + montagem das rotas
├── modules/                  # um diretório por domínio (Controller → UseCase → Repository)
│   ├── auth/                 # register, login, JWT
│   ├── users/                # perfil (GET/PATCH/DELETE me)
│   ├── services/             # tipos de serviço (CRUD)
│   ├── reservations/         # core do domínio
│   └── notifications/        # inbox persistente de notificações
├── infra/
│   ├── database/             # DataSource TypeORM + migrations
│   ├── messaging/            # conexão RabbitMQ, producer e consumers
│   └── websocket/            # servidor WS + registry userId → conexão
└── shared/
    ├── container/            # injeção de dependência (factories)
    ├── middlewares/          # authMiddleware, roleMiddleware
    ├── enums/                # Role, ReservationStatus
    └── errors/               # AppError centralizado
```

---

## Pré-requisitos

- **Node.js** 20 ou superior
- **Docker** e Docker Compose (para o RabbitMQ)
- Um **PostgreSQL** acessível — pode ser local, em container ou gerenciado (ex.: Supabase). A connection string vai na variável `DATABASE_URL`.

---

## Configuração

### 1. Variáveis de ambiente

```bash
cp .env.example .env
```

| Variável | Descrição | Exemplo |
|---|---|---|
| `NODE_ENV` | Ambiente de execução | `development` |
| `PORT` | Porta do servidor HTTP (e do WebSocket) | `3000` |
| `DATABASE_URL` | Connection string completa do PostgreSQL | `postgresql://user:pass@host:5432/db` |
| `RABBITMQ_URL` | URL do broker RabbitMQ | `amqp://admin:admin@localhost:5672` |
| `JWT_SECRET` | Segredo usado para assinar os tokens | `troque_em_producao` |
| `JWT_EXPIRES_IN` | Validade do token | `7d` |

> **SSL:** o `DataSource` ativa SSL automaticamente quando a `DATABASE_URL` **não** aponta para `localhost` (necessário para bancos gerenciados como o Supabase).

### 2. Instale as dependências

```bash
npm install
```

### 3. Suba o RabbitMQ

A partir da raiz do repositório:

```bash
docker-compose up -d rabbitmq
```

- AMQP em `localhost:5672`
- Management UI em `http://localhost:15672` (user: `admin` / pass: `admin`)

> O `docker-compose.yml` na raiz também consegue subir o próprio backend (`docker-compose up -d`). Rodar via `npm run dev` é recomendado em desenvolvimento pelo hot-reload.

### 4. Execute as migrations

```bash
npm run migration:run
```

Cria o schema completo: `users`, `service_types`, `reservations`, `notifications` e os enums/constraints associados.

### 5. Inicie o servidor

```bash
npm run dev
```

Ao subir, o `server.ts`:
1. Conecta no PostgreSQL (`Database connected`);
2. Sobe o servidor HTTP **e** o WebSocket no mesmo processo/porta (`Server running on port 3000`);
3. Inicia os dois consumers do RabbitMQ (`NotificationConsumer` e `ReservationCommandConsumer`).

---

## Scripts

| Script | Descrição |
|---|---|
| `npm run dev` | Servidor em desenvolvimento com hot-reload (`ts-node-dev`) |
| `npm run build` | Compila TypeScript para `dist/` |
| `npm run start` | Executa o build compilado (`node dist/server.js`) |
| `npm run migration:run` | Aplica todas as migrations pendentes |
| `npm run migration:generate` | Gera nova migration a partir das entidades |
| `npm run migration:revert` | Reverte a última migration |

---

## Endpoints (resumo)

| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/auth/register` | Cadastra usuário (CLIENT ou PROVIDER) | — |
| POST | `/auth/login` | Autentica e retorna JWT | — |
| GET | `/users/me` | Perfil do usuário autenticado | Autenticado |
| PATCH | `/users/me` | Atualiza nome/e-mail | Autenticado |
| DELETE | `/users/me` | Remove a conta | Autenticado |
| POST | `/services` | Cria tipo de serviço | PROVIDER |
| GET | `/services` | Lista serviços disponíveis | Autenticado |
| GET | `/services/:id` | Detalhe de um serviço | Autenticado |
| PATCH | `/services/:id` | Atualiza serviço | PROVIDER |
| POST | `/reservations` | Cria reserva (assíncrono, `202`) | CLIENT |
| GET | `/reservations` | Lista reservas do usuário | Autenticado |
| GET | `/reservations/:id` | Detalhe de uma reserva | Autenticado |
| PATCH | `/reservations/:id/status` | Aceita / recusa / conclui | PROVIDER |
| PATCH | `/reservations/:id/cancel` | Cancela reserva (regras por role) | CLIENT/PROVIDER |
| GET | `/notifications` | Inbox + `unreadCount` | Autenticado |
| PATCH | `/notifications/:id/read` | Marca uma como lida | Autenticado |
| PATCH | `/notifications/read-all` | Marca todas como lidas | Autenticado |

Detalhes de request/response em [`docs/api.md`](../docs/api.md).

---

## Mensageria (RabbitMQ)

Dois padrões EIP estão em uso:

- **Command Message** — `POST /reservations` publica na fila `reservation.commands` e responde `202 Accepted`. O `ReservationCommandConsumer` processa com `prefetch(1)` (serialização) e verifica conflito de horário antes de persistir.
- **Event Notification** — operações de domínio publicam eventos no exchange `reservations` (tipo `topic`). O `NotificationConsumer` (binding `reservation.*` e `service.*`) persiste a notificação e, se o destinatário estiver online, entrega via WebSocket.

A tabela completa de eventos e payloads está em [`docs/events.md`](../docs/events.md).

---

## WebSocket

Conexão: `ws://localhost:3000?token=<jwt>` (mesma porta do HTTP).

O servidor valida o JWT, registra a conexão por `userId` e, ao receber um evento de notificação, envia:

```json
{ "event": "notification.new", "payload": { "...notification_row..." } }
```

Usuários offline não perdem nada — as notificações ficam persistidas e podem ser recuperadas em `GET /notifications`.
