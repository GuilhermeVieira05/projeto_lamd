# Mobile — Reserva de Serviços

App Flutter único que atende os **dois perfis** do sistema — `CLIENT` e `PROVIDER` — com a interface determinada pelo papel do usuário logado (role guard no `go_router`).

## Requisitos

- Flutter 3.x instalado
- Xcode (para iOS Simulator) ou Android SDK
- Backend rodando em `localhost:3000` (ver `docker-compose` e [`backend/README.md`](../backend/README.md))

## Setup

```bash
cd mobile
flutter pub get
```

## Executar

```bash
# Listar dispositivos/simuladores disponíveis:
flutter devices

# Rodar (ex.: iOS Simulator):
flutter run -d "iPhone 16"
```

> Para demonstrar o fluxo ponta a ponta, rode **duas instâncias**: uma logada como CLIENT e outra como PROVIDER.

## Estrutura

```
lib/
├── core/
│   ├── auth/          # AuthProvider, TokenStorage, RoleGuard
│   ├── network/       # HttpClient (Dio+JWT), WsClient (WebSocket)
│   ├── storage/       # LocalDb (cache SQLite)
│   ├── notifications/ # NotificationProvider (inbox + toast)
│   ├── widgets/       # AppShell (bottom nav por papel)
│   └── router/        # AppRouter (go_router com role guard)
└── features/
    ├── auth/          # Login e Registro (seletor de papel)
    ├── client/        # Telas do CLIENT
    └── provider/      # Telas do PROVIDER
```

## Telas por perfil

**CLIENT** — abas `Serviços · Reservas · Notificações · Perfil`
1. Lista de serviços disponíveis (busca/categorias)
2. Detalhe do serviço → escolher data/hora → criar reserva
3. Minhas Reservas — status em tempo real (WebSocket) + filtros
4. Notificações (inbox) e Perfil

**PROVIDER** — abas `Reservas · Meus Serviços · Perfil`
1. **Reservas** — uma tela com chips de status (**Pendentes / Ativas / Concluídas**). Reservas pendentes chegam em tempo real via WebSocket; cancelamentos do cliente somem da lista sozinhos.
2. Detalhe da reserva → **Aceitar / Recusar**; em ativas → **Marcar como Concluído**.
3. **Meus Serviços** — lista os serviços do próprio prestador; botão **+** para cadastrar; tocar num serviço abre o formulário para **editar** ou **desativar/ativar**.
4. Perfil.

Ambas as listas do prestador têm **pull-to-refresh**.

## Atualização em tempo real

O `WsClient` abre uma conexão `ws://localhost:3000?token=<jwt>` após o login. Eventos `notification.new` atualizam as telas sem ação do usuário:
- CLIENT: `reservation.accepted | refused | completed` atualizam o status na lista.
- PROVIDER: `reservation.created` insere uma nova pendente; `reservation.cancelled` remove a pendente cancelada pelo cliente.

## Tecnologias

| Camada | Tecnologia |
|---|---|
| State management | Provider |
| HTTP | Dio + interceptor JWT |
| WebSocket | web_socket_channel |
| Cache offline | sqflite |
| Navegação | go_router (guard por papel) |
| Design | Cupertino (tema escuro) |
