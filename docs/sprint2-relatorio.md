# Sprint 2 — Relatório de Integração com RabbitMQ

## 1. Objetivo

Integrar comunicação assíncrona ao backend via RabbitMQ (MOM — Message-Oriented Middleware), publicando eventos de domínio nas filas e notificando usuários em tempo real via WebSocket.

---

## 2. Tabela de Eventos

| Evento (Routing Key) | Produtor | Consumidor | Destino WS | Payload |
|---|---|---|---|---|
| `reservation.created` | `CreateReservationUseCase` | `consumer.ts` → WS | Prestador (`providerId`) | `{ targetUserId, reservationId, clientName, serviceType, scheduledAt }` |
| `reservation.accepted` | `UpdateReservationStatusUseCase` | `consumer.ts` → WS | Cliente (`clientId`) | `{ targetUserId, reservationId, providerName, scheduledAt }` |
| `reservation.refused` | `UpdateReservationStatusUseCase` | `consumer.ts` → WS | Cliente (`clientId`) | `{ targetUserId, reservationId, providerName, scheduledAt }` |
| `reservation.completed` | `UpdateReservationStatusUseCase` | `consumer.ts` → WS | Cliente (`clientId`) | `{ targetUserId, reservationId, providerName, scheduledAt, completedAt }` |

**Exchange:** `reservations` (type: `topic`, durable: true)  
**Fila:** `reservation.notifications` (binding: `reservation.*`, durable: true)

---

## 3. Arquitetura da Integração

```
POST /reservations
    └─→ CreateReservationUseCase
            └─→ IEventPublisher.publish("reservation.created", payload)
                    └─→ RabbitMQProducer → Exchange "reservations" → Queue "reservation.notifications"
                                                                              ↓
                                                                    consumer.ts (startConsumers)
                                                                              ↓
                                                              wsRegistry.send(targetUserId, event, payload)
                                                                              ↓
                                                                    WebSocket → Prestador
```

```
PATCH /reservations/:id/status
    └─→ UpdateReservationStatusUseCase
            └─→ IEventPublisher.publish("reservation.accepted|refused|completed", payload)
                    └─→ RabbitMQProducer → Exchange "reservations" → Queue "reservation.notifications"
                                                                              ↓
                                                                    consumer.ts (startConsumers)
                                                                              ↓
                                                              wsRegistry.send(targetUserId, event, payload)
                                                                              ↓
                                                                    WebSocket → Cliente
```

---

## 4. Decisões Técnicas

### Por que RabbitMQ?
RabbitMQ é um message broker maduro com suporte a persistência de mensagens, exchanges com roteamento flexível e consumer groups. Diferente de uma chamada HTTP direta, o producer não depende da disponibilidade do consumer — desacoplamento temporal real (EIP: *Decoupled Communication*).

### Por que Topic Exchange?
O exchange do tipo `topic` permite roteamento baseado em padrões de routing key (ex: `reservation.*`). Isso possibilita que consumidores futuros assinem eventos específicos (ex: apenas `reservation.created`) sem modificar o producer — princípio Open/Closed (SOLID).

### Princípio DIP nos UseCases
Os UseCases dependem da interface `IEventPublisher`, não de `RabbitMQProducer` diretamente. A injeção ocorre no container (`shared/container/index.ts`). Isso permite substituir o MOM por qualquer outro broker sem alterar a lógica de domínio.

### WebSocket como Bridge MOM → Cliente
O consumer RabbitMQ busca a conexão WebSocket do usuário destino no `wsRegistry` (mapa userId → WebSocket) e envia o evento JSON diretamente. A autenticação do WebSocket é feita via JWT no query param `token`.

---

## 5. Estrutura de Arquivos Implementados

```
backend/src/infra/
├── messaging/
│   ├── rabbitmq.connection.ts   # Singleton de conexão + setup exchange/queue
│   ├── producer.ts              # IEventPublisher + RabbitMQProducer
│   ├── consumer.ts              # startConsumers() — listener da fila
│   └── index.ts                 # Re-exports
└── websocket/
    ├── ws.server.ts             # Inicializa WebSocketServer no http.Server
    ├── ws.registry.ts           # Mapa userId → WebSocket connection
    └── index.ts                 # Re-exports
```

---

## 6. Como Demonstrar o Funcionamento

### Pré-requisitos
```bash
docker-compose up -d
cd backend && npm run dev
```

### Fluxo de demonstração

1. Registrar um prestador e um cliente via `POST /auth/register`
2. Fazer login de ambos via `POST /auth/login`
3. Prestador conecta ao WebSocket: `ws://localhost:3000?token=<jwt_provider>`
4. Cliente conecta ao WebSocket: `ws://localhost:3000?token=<jwt_client>`
5. Prestador cria um serviço via `POST /services`
6. Cliente cria uma reserva via `POST /reservations`
7. **Observar no terminal do backend:** log do producer e do consumer
8. **Observar na conexão WS do prestador:** evento `reservation.created` recebido em tempo real
9. Prestador aceita via `PATCH /reservations/:id/status` com `{ "status": "ACCEPTED" }`
10. **Observar na conexão WS do cliente:** evento `reservation.accepted` recebido em tempo real

### Management UI
Acesse `http://localhost:15672` (admin/admin) para visualizar:
- Exchange `reservations` com bindings
- Fila `reservation.notifications` com mensagens processadas

---

## 7. Desafios e Soluções

| Desafio | Solução |
|---|---|
| API do amqplib mudou — `connect()` retorna `ChannelModel` em vez de `Connection` | Usar o tipo `ChannelModel` importado do amqplib |
| Consumer precisa do wsRegistry que é criado depois | Dynamic `import()` no consumer com try/catch — tolerante à ordem de inicialização |
| WebSocket precisa ser anexado ao mesmo servidor HTTP do Express | Refatorado `server.ts` para usar `http.createServer(app)` explicitamente |
| UseCases não podiam depender do RabbitMQ diretamente | Interface `IEventPublisher` injetada via container (DIP) |

---

## 8. Referências

- HOHPE, Gregor; WOOLF, Bobby. **Enterprise Integration Patterns**. Addison-Wesley, 2003.
- RabbitMQ Documentation. Topic Exchanges. Disponível em: https://www.rabbitmq.com/tutorials/tutorial-five-javascript
- MARTIN, Robert C. **Clean Architecture**. Prentice Hall, 2017. (Dependency Inversion Principle)
