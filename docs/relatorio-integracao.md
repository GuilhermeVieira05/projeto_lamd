# Relatório de Integração — MOM (RabbitMQ)

## Escolha da Ferramenta

O RabbitMQ foi escolhido como Message Broker por ser uma solução madura, amplamente adotada e de fácil configuração local via Docker. Seu modelo baseado em exchanges e filas com suporte a múltiplos padrões de roteamento (direct, topic, fanout) oferece a flexibilidade necessária para os dois padrões de mensageria implementados. A interface de gerenciamento web (Management UI) também facilita a observação das filas durante o desenvolvimento e nas demonstrações.

---

## Padrões Utilizados

Foram implementados dois padrões EIP (Enterprise Integration Patterns):

**Command Message** — aplicado na criação de reservas. O endpoint `POST /reservations` publica um comando na fila `reservation.commands` e retorna imediatamente `202 Accepted`, sem aguardar o processamento. O `ReservationCommandConsumer` processa o comando de forma assíncrona, verificando disponibilidade de horário e persistindo a reserva. O canal deste consumer opera com `prefetch(1)`, garantindo que apenas uma mensagem seja processada por vez — estratégia que serializa as criações e resolve a condição de corrida quando dois clientes tentam reservar o mesmo horário simultaneamente.

**Event Notification** — aplicado após operações de domínio. Sempre que o estado de uma reserva muda (criada, aceita, recusada, concluída, cancelada) ou um serviço é atualizado, o UseCase correspondente publica um evento no exchange `reservations` (tipo `topic`). O `NotificationConsumer`, inscrito via binding `reservation.*` e `service.*`, recebe esses eventos, persiste a notificação no banco de dados e, se o destinatário estiver conectado via WebSocket, entrega o evento em tempo real.

---

## Arquitetura de Mensagens

| Fila | Exchange | Consumer | Função |
|---|---|---|---|
| `reservation.commands` | default (direto) | `ReservationCommandConsumer` | Processa criação serializada |
| `notification.persist` | `reservations` (topic) | `NotificationConsumer` | Persiste e entrega notificações |

Um único producer (`RabbitMQProducer`) é utilizado por todos os UseCases, publicando no exchange `reservations`. A criação de reservas utiliza `sendToQueue` diretamente na fila de comandos, desacoplando o fluxo síncrono do processamento assíncrono.

---

## WebSocket como bridge MOM → App

O RabbitMQ entrega eventos para o backend, mas o app Flutter precisa receber essas notificações em tempo real. A solução foi uma bridge interna: o `NotificationConsumer`, após processar cada evento da fila, consulta um registry (`ws.registry.ts`) que mantém o mapa `userId → WebSocket connection`. Se o destinatário estiver conectado, o evento é empurrado imediatamente como uma mensagem JSON `{ event, payload }` via WebSocket. Caso contrário, a notificação fica persistida no banco e o app a recupera pelo endpoint `GET /notifications` na próxima abertura. Isso separa claramente as responsabilidades: o MOM garante que o backend processe o evento; o WebSocket é apenas o canal de entrega de baixa latência, não a fonte de verdade.

---

## Desafios Encontrados

**Controle de concorrência:** o principal desafio foi garantir que duas reservas simultâneas para o mesmo horário não fossem aceitas. A solução foi combinar `prefetch(1)` no canal do command consumer com uma verificação de conflito antes de persistir — o prefetch garante serialização, e a verificação garante integridade dos dados.

**Identidade da conexão WebSocket:** para entregar um evento ao usuário correto, o servidor precisa saber qual socket pertence a qual usuário. A solução foi exigir o JWT como query param na abertura da conexão (`ws://host?token=...`), validá-lo no handshake e registrar o socket com a chave `userId`. Conexões encerradas são removidas do mapa automaticamente, e o app reconecta após o login.

**Usuários offline não podem perder eventos:** entregar só por WebSocket deixaria usuários desconectados sem saber das mudanças de estado. O `NotificationConsumer` sempre persiste a notificação no banco antes de tentar a entrega via WebSocket — independentemente de o usuário estar online ou não. Assim, ao abrir o app depois de um período offline, o cliente vê todas as notificações pendentes pelo inbox REST, e o badge de não lidas reflete o estado real.
