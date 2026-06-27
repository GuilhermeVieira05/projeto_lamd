---
name: client-answers
description: Design da feature de perguntas do prestador + respostas do cliente na reserva
metadata:
  type: project
---

# Feature — Perguntas do Prestador / Respostas do Cliente

**Data:** 2026-06-26  
**Motivação:** Pedido do professor na avaliação da Sprint 3 — permitir interação entre solicitação de serviço e confirmação, onde o prestador define quais informações quer do cliente ao criar o serviço, e o cliente preenche as respostas antes de confirmar a reserva.

---

## Solução

Campos JSONB nas tabelas existentes — sem novas entidades ou repositórios.

- `service_types.required_fields: jsonb` — lista de perguntas definidas pelo prestador
- `reservations.client_answers: jsonb` — mapa `{ pergunta: resposta }` preenchido pelo cliente

---

## Banco de Dados

### Migration A — `service_types`

```sql
ALTER TABLE service_types
  ADD COLUMN required_fields jsonb NOT NULL DEFAULT '[]';
```

### Migration B — `reservations`

```sql
ALTER TABLE reservations
  ADD COLUMN client_answers jsonb NOT NULL DEFAULT '{}';
```

Nomenclatura de arquivo: próximos dois timestamps sequenciais após a última migration existente (`1747210000000`).

---

## Backend

### Entidades TypeORM

**`ServiceType`** ganha:
```ts
@Column({ name: 'required_fields', type: 'jsonb', default: [] })
requiredFields: string[];
```

**`Reservation`** ganha:
```ts
@Column({ name: 'client_answers', type: 'jsonb', default: {} })
clientAnswers: Record<string, string>;
```

### DTOs

**`CreateServiceDTO` / `UpdateServiceDTO`** ganham campo opcional:
```ts
requiredFields: z.array(z.string().min(1).max(200)).max(10).optional().default([])
```

**`CreateReservationDTO`** ganha:
```ts
clientAnswers: z.record(z.string(), z.string()).optional().default({})
```

### Validação no `CreateReservationUseCase`

Após buscar o `ServiceType`, antes de persistir a reserva:

```
para cada pergunta em serviceType.requiredFields:
  se clientAnswers[pergunta] estiver ausente ou vazio:
    lançar AppError(400, "Resposta obrigatória: <pergunta>")
```

### Respostas nas APIs existentes

Os endpoints já existentes (`GET /services/:id`, `GET /reservations`, `GET /reservations/:id`) passam a incluir os novos campos nos objetos retornados — sem rotas novas.

---

## Mobile (Flutter)

### `ServiceFormScreen` — lado do prestador

Nova seção abaixo dos campos existentes: **"Informações solicitadas ao cliente"**.

- Lista das perguntas já cadastradas, cada uma com botão de remover (ícone de lixeira)
- Campo de texto + botão "Adicionar pergunta"
- Máximo de 10 perguntas (validado no frontend antes de chamar a API)
- Ao salvar (`create` ou `update`), envia `requiredFields` no body

### `ServiceDetailScreen` — lado do cliente

Se `service.requiredFields` não estiver vazio, exibe seção **"Informações necessárias"** entre a seção do prestador e o botão de confirmar.

- Cada pergunta vira um `CupertinoTextField` com o texto da pergunta como label
- O botão "Confirmar Reserva" fica desabilitado até que todos os campos estejam preenchidos
- As respostas são enviadas como `clientAnswers` no `createReservation`

### `ReservationDetailScreen` — lado do prestador

Se `reservation.clientAnswers` tiver entradas, exibe seção **"Informações do cliente"** antes dos botões de aceitar/recusar.

- Cada entrada exibe a pergunta (label cinza) e a resposta (texto branco)
- Mesmo estilo de card `_Section` já usado no projeto

---

## Fluxo completo

```
Prestador cria serviço → define perguntas em required_fields
    ↓
Cliente abre serviço → vê campos de resposta obrigatórios
    ↓
Cliente preenche respostas → confirma reserva (client_answers enviado)
    ↓
Backend valida: todas as perguntas respondidas? → persiste reserva
    ↓
Prestador abre reserva → vê respostas do cliente → aceita/recusa
```

---

## Critérios de conclusão

1. Prestador consegue adicionar/remover perguntas no `ServiceFormScreen` e salvar
2. Cliente vê os campos de resposta no `ServiceDetailScreen` e não consegue confirmar sem preencher
3. Backend rejeita reserva com perguntas não respondidas (400)
4. Prestador vê as respostas no `ReservationDetailScreen`
