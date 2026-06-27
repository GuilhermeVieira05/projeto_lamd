# Sistema de Reserva de Serviços

Plataforma onde clientes reservam serviços e prestadores gerenciam essas reservas em tempo real. Projeto desenvolvido para a disciplina **Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas** — PUC Minas, 1º Semestre 2026.

## Arquitetura

```
Flutter App ──REST──► Node.js + Express + TypeORM ──► PostgreSQL
                                │
                           RabbitMQ (MOM)
                                │
                          WebSocket Server ──► Flutter App
```

| Camada | Tecnologia |
|---|---|
| Backend | Node.js + Express + TypeScript + TypeORM |
| Banco de dados | PostgreSQL |
| Mensageria (MOM) | RabbitMQ |
| App Mobile | Flutter + Dart |
| Autenticação | JWT (roles: CLIENT / PROVIDER) |
| Infraestrutura | Docker + Docker Compose |

## Estrutura do Repositório

```
.
├── backend/          # API REST (Node.js + Express + TypeORM)
├── mobile/           # App Flutter (CLIENT + PROVIDER)
├── docs/
│   ├── api.md                      # Documentação de endpoints com exemplos
│   ├── events.md                   # Catálogo de eventos RabbitMQ
│   ├── postman-collection.json     # Coleção Postman exportada
│   ├── proposta-dominio.md         # Proposta de domínio
│   ├── arquitetura.md              # Diagramas de arquitetura e DER
│   ├── arquitetura-flutter.md      # Camadas internas do app Flutter
│   ├── relatorio-integracao.md     # Relatório MOM — Sprint 2
│   ├── relatorio-final.md          # Relatório técnico final
│   ├── plano-desenvolvimento.md    # Plano de sprints
│   └── images/
│       ├── DiagramaArquitetura.png
│       └── DiagramaDER.png
└── docker-compose.yml
```

## Pré-requisitos

- [Node.js](https://nodejs.org/) v20+
- [Flutter](https://flutter.dev/) v3.x
- [Docker](https://www.docker.com/) e Docker Compose
- [Git](https://git-scm.com/)

## Como Rodar o Projeto

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd Projeto
```

### 2. Suba os serviços de infraestrutura (PostgreSQL + RabbitMQ)

```bash
docker-compose up -d
```

Aguarde os containers ficarem healthy. Para verificar:

```bash
docker-compose ps
```

- PostgreSQL disponível em `localhost:5432`
- RabbitMQ Management UI em `http://localhost:15672` (user: `admin` / pass: `admin`)

### 3. Configure as variáveis de ambiente do backend

```bash
cd backend
cp .env.example .env
```

Edite o `.env` conforme necessário. Para usar o banco local do Docker, os valores padrão já funcionam. Para usar o Supabase, substitua as variáveis de PostgreSQL pela connection string fornecida:

```env
POSTGRES_HOST=<host-supabase>
POSTGRES_PORT=5432
POSTGRES_USER=<user-supabase>
POSTGRES_PASSWORD=<senha-supabase>
POSTGRES_DB=<nome-db-supabase>
```

### 4. Instale as dependências do backend

```bash
cd backend   # se ainda não estiver nesta pasta
npm install
```

### 5. Execute as migrations

```bash
npm run migration:run
```

### 6. Inicie o servidor de desenvolvimento

```bash
npm run dev
```

O servidor estará disponível em `http://localhost:3000`.

### 7. Rode o app Flutter

```bash
cd ../mobile
flutter pub get
flutter run
```

O app detecta automaticamente o role do usuário logado e exibe as telas correspondentes (CLIENT ou PROVIDER).

## Scripts Disponíveis (backend)

| Script | Descrição |
|---|---|
| `npm run dev` | Servidor em modo desenvolvimento com hot-reload |
| `npm run build` | Compila TypeScript para `dist/` |
| `npm run start` | Executa o build compilado |
| `npm run migration:run` | Aplica todas as migrations pendentes |
| `npm run migration:generate` | Gera uma nova migration baseada nas entidades |
| `npm run migration:revert` | Reverte a última migration |

## Endpoints da API

Documentação completa com exemplos de request e response em [`docs/api.md`](docs/api.md).

Coleção Postman exportada em [`docs/postman-collection.json`](docs/postman-collection.json) — importe no Postman e configure a variável `base_url` para `http://localhost:3000`.

### Resumo das rotas

| Método | Rota | Descrição | Auth |
|---|---|---|---|
| POST | `/auth/register` | Cadastra usuário (CLIENT ou PROVIDER) | — |
| POST | `/auth/login` | Autentica e retorna JWT | — |
| POST | `/services` | Cria tipo de serviço | PROVIDER |
| GET | `/services` | Lista serviços disponíveis | Autenticado |
| GET | `/services/:id` | Detalhe de um serviço | Autenticado |
| PATCH | `/services/:id` | Atualiza serviço | PROVIDER |
| POST | `/reservations` | Cria reserva | CLIENT |
| GET | `/reservations` | Lista reservas do usuário | Autenticado |
| GET | `/reservations/:id` | Detalhe de uma reserva | Autenticado |
| PATCH | `/reservations/:id/status` | Atualiza status da reserva | PROVIDER |

## Fluxo Principal

```
1.  Prestador se cadastra e cadastra seus serviços (com perguntas obrigatórias ao cliente)
2.  Cliente se cadastra e navega no catálogo
3.  Cliente abre um serviço, preenche as respostas obrigatórias e cria uma reserva
4.  Backend publica comando na fila reservation.commands → retorna 202 Accepted
5.  ReservationCommandConsumer processa (prefetch 1) e persiste no PostgreSQL
6.  Consumer publica reservation.created → NotificationConsumer entrega via WebSocket
7.  Prestador vê a reserva aparecer em tempo real (badge "Nova") com as respostas do cliente
8.  Prestador aceita ou recusa → status: ACCEPTED | REFUSED
9.  Backend publica reservation.accepted/refused → WebSocket notifica o cliente
10. Cliente vê status atualizado sem refresh
11. Prestador marca como concluído → status: COMPLETED → cliente recebe notificação final
```

## Documentação

- [Proposta de Domínio](docs/proposta-dominio.md)
- [Diagrama de Arquitetura](docs/images/DiagramaArquitetura.png)
- [Diagrama ER](docs/images/DiagramaDER.png)
- [Documentação de Endpoints](docs/api.md)
- [Catálogo de Eventos RabbitMQ](docs/events.md)
- [Arquitetura Flutter](docs/arquitetura-flutter.md)
- [Relatório de Integração MOM](docs/relatorio-integracao.md)
- [Relatório Técnico Final](docs/relatorio-final.md)
- [Plano de Desenvolvimento](docs/plano-desenvolvimento.md)
