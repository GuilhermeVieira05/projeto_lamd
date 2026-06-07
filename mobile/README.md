# Mobile — Reserva de Serviços

App Flutter para o perfil CLIENT do sistema de reservas (Sprint 3).

## Requisitos

- Flutter 3.x instalado
- Xcode (para iOS Simulator)
- Backend rodando em `localhost:3000` (ver docker-compose na raiz)

## Setup

```bash
cd mobile
flutter pub get
```

## Executar

```bash
# Listar simuladores disponíveis:
flutter devices

# Rodar no iOS Simulator:
flutter run -d "iPhone 16"
```

## Estrutura

```
lib/
├── core/
│   ├── auth/          # AuthProvider, TokenStorage, RoleGuard
│   ├── network/       # HttpClient (Dio+JWT), WsClient (WebSocket)
│   ├── storage/       # LocalDb (SQLite cache)
│   └── router/        # AppRouter (go_router com role guard)
└── features/
    ├── auth/          # Login e Registro
    └── client/        # Telas do CLIENT: serviços, reservas
```

## Fluxo principal (CLIENT)

1. Login → redireciona para lista de serviços
2. Tap num serviço → tela de detalhe → escolher data/hora → Confirmar Reserva
3. Minhas Reservas → status atualiza em tempo real via WebSocket

## Tecnologias

| Camada | Tecnologia |
|---|---|
| State management | Provider |
| HTTP | Dio + interceptor JWT |
| WebSocket | web_socket_channel |
| Cache offline | sqflite |
| Navegação | go_router |
| Design | Cupertino (iOS nativo) |
