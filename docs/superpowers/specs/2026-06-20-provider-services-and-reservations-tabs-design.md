# Design — Reorganização das telas do Prestador + Cadastro de Serviços

**Data:** 2026-06-20
**Escopo:** App Flutter (perfil PROVIDER) + endpoint de apoio no backend

---

## Contexto e Motivação

O app do prestador hoje tem duas abas de reservas separadas (**Pendentes** e **Ativas**) e **não oferece nenhuma forma de cadastrar serviços** — o prestador precisaria usar o Postman para criar um `service_type`. Isso deixa um buraco no fluxo do domínio (o prestador "cadastra os serviços que oferece").

Duas mudanças:
1. **Unificar** as telas de reservas numa única aba **Reservas** com filtro de status em chips (Pendentes / Ativas / Concluídas).
2. **Adicionar** uma aba **Meus Serviços** que lista os serviços do prestador e permite cadastrar um novo.

## Objetivos

- Prestador consegue cadastrar um novo serviço pelo app (`POST /services`).
- Prestador vê a lista dos seus próprios serviços.
- Reservas do prestador ficam numa só tela, filtráveis por status via chips.
- Reaproveitar o padrão de chips já usado na tela do cliente (`MyReservationsScreen`).

## Não-objetivos (YAGNI)

- Editar ou desativar serviços pelo app (o backend tem `PATCH /services/:id`, mas fica fora deste escopo).
- Filtro por tempo (futuras/passadas) na tela de reservas do prestador.
- Mostrar reservas `REFUSED`/`CANCELLED` na lista (apenas PENDING/ACCEPTED/COMPLETED).

---

## Navegação

A navbar do prestador muda de `[Pendentes] [Ativas] [Perfil]` para:

```
[ Reservas ]   [ Meus Serviços ]   [ Perfil ]
   clock          briefcase           person
```

Rotas (`app_router.dart`, shell do PROVIDER):

| Rota | Tela |
|---|---|
| `/provider/reservations` | `ReservationsScreen` (unificada) |
| `/provider/reservations/:id` | `ReservationDetailScreen` (inalterada; recebe o model via `extra`) |
| `/provider/services` | `MyServicesScreen` (lista + botão "+") |
| `/provider/services/new` | `CreateServiceScreen` (formulário) |
| `/provider/profile` | `ProfileScreen` (inalterada) |

Redirecionamentos em `app_router.dart` que hoje apontam para `/provider/pending` passam a apontar para `/provider/reservations` (login de PROVIDER e bloqueio de CLIENT em rota de provider).

---

## Parte 1 — Tela "Reservas" (unifica Pendentes + Ativas)

**Arquivo novo:** `features/provider/screens/reservations_screen.dart`
**Arquivos removidos:** `pending_reservations_screen.dart`, `active_reservations_screen.dart`

Layout: título "Reservas" + linha de chips (seleção única, padrão **Pendentes**) + lista filtrada.

```
Reservas
( Pendentes ) ( Ativas ) ( Concluídas )
 • Corte de Cabelo — João      [Nova]
 • Limpeza — Maria
```

Comportamento do card por status:
- **PENDING** — badge "Nova" para itens recém-chegados; tap abre `/provider/reservations/:id` (Aceitar/Recusar). Mantém a chegada em tempo real via WebSocket.
- **ACCEPTED** — botão inline "Marcar como Concluído" (com diálogo de confirmação já corrigido).
- **COMPLETED** — read-only (sem ações).

Estados: loading (spinner quando lista vazia), erro (mensagem), vazio (mensagem por filtro, ex.: "Nenhuma reserva pendente").

### `ProviderReservationsProvider` — mudanças

- Passa a manter **três** buckets: `_pending`, `_active`, `_completed` (hoje `complete()` descarta o item; agora move para `_completed`).
- `load()` deixa de filtrar só PENDING/ACCEPTED: separa os três status a partir do `listAll()`.
- Novo estado `StatusFilter` (enum `pending | active | completed`) + `setStatusFilter()`.
- Getter `visibleReservations` retorna o bucket conforme o filtro ativo.
- WebSocket (`reservation.created`) continua inserindo em `_pending` (inalterado).
- `refuse()` remove de `_pending` (inalterado). `accept()` move pending→active (inalterado). `complete()` move active→completed.

---

## Parte 2 — Aba "Meus Serviços" (catálogo + cadastrar)

### Backend — novo endpoint `GET /services/mine` (abordagem A, aprovada)

Retorna os serviços do prestador autenticado (ativos **e** inativos), ordenados por `createdAt` desc.

Mudanças (seguindo Controller → UseCase → Repository já existente):
- `IServiceRepository`: adicionar `findByProvider(providerId: string): Promise<ServiceType[]>`.
- `ServiceRepository`: implementar `findByProvider` → `find({ where: { providerId }, relations: ['provider'], order: { createdAt: 'DESC' } })`.
- `ListMyServicesUseCase`: `execute(providerId)` → `repo.findByProvider(providerId)`.
- `container/index.ts`: `makeListMyServicesUseCase()`.
- `ServiceController.listMine(req,res)` → `makeListMyServicesUseCase().execute(req.user!.id)`.
- `service.routes.ts`: `GET /mine` com `authMiddleware` + `roleMiddleware(PROVIDER)`, **declarado ANTES de `/:id`** (senão `/:id` captura "mine").

> `POST /services` e `CreateServiceDTO` (name, description≥10, price>0, durationMinutes int>0) já existem — sem mudança.

### Mobile — camada de serviços do provider

**Arquivo novo:** `features/provider/services/provider_services_api.dart`
- `ProviderServiceModel { id, name, description, price (double), durationMinutes (int), active (bool) }` com `fromJson` (price via `double.parse(json['price'].toString())`, durationMinutes camelCase).
- `ProviderServicesApi`:
  - `listMine()` → `GET /services/mine`
  - `create({name, description, price, durationMinutes})` → `POST /services` (body camelCase) → retorna `ProviderServiceModel`.

**Arquivo novo:** `features/provider/providers/provider_services_provider.dart` (`ChangeNotifier`)
- Estado: `List<ProviderServiceModel> services`, `isLoading`, `error`.
- `load()` → chama `listMine()`.
- `create(...)` → chama api, em sucesso insere no topo da lista e `notifyListeners()`.

Registrar no `main.dart` (MultiProvider) com `ProviderServicesApi(http: _httpClient)`.

### Mobile — telas

**Arquivo novo:** `features/provider/screens/my_services_screen.dart`
```
Meus Serviços                         [ + ]
 • Corte de Cabelo   R$50 · 30min   [Ativo]
 • Limpeza           R$150 · 180min [Ativo]
```
- Carrega em `initState`. Botão "+" (trailing da nav bar) → `context.push('/provider/services/new')`.
- Estados loading/erro/vazio ("Você ainda não cadastrou serviços").
- Card read-only: nome, preço formatado, duração, badge Ativo/Inativo.

**Arquivo novo:** `features/provider/screens/create_service_screen.dart`
- Formulário Cupertino: Nome, Descrição (multiline), Preço (teclado decimal), Duração em minutos (teclado numérico).
- Validação client-side espelhando o DTO: nome 2–100, descrição ≥10, preço > 0, duração inteiro > 0. Erros inline antes de enviar.
- Botão "Salvar": chama `provider.create(...)`; em sucesso `context.pop()` (volta para a lista, que já reflete o novo item); em erro mostra diálogo (usando `Navigator.of(dialogContext, rootNavigator: true)` — padrão correto).

---

## Fluxo de dados

```
Cadastrar serviço:
  CreateServiceScreen → ProviderServicesProvider.create()
    → ProviderServicesApi.create() → POST /services (201)
    → insere no estado → pop → MyServicesScreen mostra o novo item

Listar meus serviços:
  MyServicesScreen.initState → provider.load()
    → ProviderServicesApi.listMine() → GET /services/mine
    → estado → lista renderizada

Reservas (inalterado no fluxo de rede):
  ReservationsScreen → ProviderReservationsProvider (load + WS)
    chips trocam o bucket exibido (pending/active/completed)
```

---

## Testes / Verificação

- `flutter analyze` limpo após as mudanças.
- `npx tsc --noEmit` limpo no backend após o endpoint novo.
- Verificação manual (runtime): logar como PROVIDER → cadastrar um serviço → ver na lista → trocar os chips de reservas. (Validação de runtime fica a cargo do usuário/sessão de teste, como nas mudanças anteriores.)
- Sem suíte de widget tests existente para essas telas; não será adicionada aqui (proporcionalidade), seguindo o padrão atual do projeto.

---

## Resumo de arquivos

**Backend (modificar):**
- `modules/services/repositories/IServiceRepository.ts` — `findByProvider`
- `modules/services/repositories/ServiceRepository.ts` — impl
- `modules/services/usecases/ListMyServicesUseCase.ts` — **novo**
- `shared/container/index.ts` — `makeListMyServicesUseCase`
- `modules/services/service.controller.ts` — `listMine`
- `modules/services/service.routes.ts` — `GET /mine` (antes de `/:id`)

**Mobile (novo):**
- `features/provider/services/provider_services_api.dart`
- `features/provider/providers/provider_services_provider.dart`
- `features/provider/screens/my_services_screen.dart`
- `features/provider/screens/create_service_screen.dart`
- `features/provider/screens/reservations_screen.dart`

**Mobile (modificar):**
- `features/provider/providers/provider_reservations_provider.dart` — bucket completed + statusFilter
- `core/widgets/app_shell.dart` — tabs/labels/icons do provider
- `core/router/app_router.dart` — rotas e redirects do provider
- `main.dart` — registrar `ProviderServicesProvider`

**Mobile (remover):**
- `features/provider/screens/pending_reservations_screen.dart`
- `features/provider/screens/active_reservations_screen.dart`

**Docs (opcional, recomendado):** atualizar `docs/api.md` com `GET /services/mine`.
