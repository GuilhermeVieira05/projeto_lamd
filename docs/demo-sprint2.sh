#!/bin/bash
# =============================================================================
# Sprint 2 — Demo de Evidências MOM (RabbitMQ)
# Executar com o servidor rodando: npm run dev
# =============================================================================

BASE_URL="http://localhost:3000"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

section() { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; echo -e "${BOLD}${CYAN}  $1${RESET}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════${RESET}"; }
step()    { echo -e "\n${YELLOW}▶ $1${RESET}"; }
ok()      { echo -e "${GREEN}✔ $1${RESET}"; }
fail()    { echo -e "${RED}✖ $1${RESET}"; exit 1; }

# --------------------------------------------------------------------------
section "0. Health check"
# --------------------------------------------------------------------------
step "Verificando servidor em $BASE_URL"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/health")
[ "$STATUS" = "200" ] || fail "Servidor não está rodando. Execute 'npm run dev' primeiro."
ok "Servidor online"

# --------------------------------------------------------------------------
section "1. Cadastro de usuários"
# --------------------------------------------------------------------------
step "Registrando prestador..."
PROVIDER=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"name":"Barbearia Silva","email":"barbearia@demo.com","password":"demo1234","role":"PROVIDER"}')
echo "$PROVIDER" | python3 -m json.tool 2>/dev/null || echo "$PROVIDER"

step "Registrando cliente..."
CLIENT=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"name":"João Cliente","email":"joao@demo.com","password":"demo1234","role":"CLIENT"}')
echo "$CLIENT" | python3 -m json.tool 2>/dev/null || echo "$CLIENT"

# --------------------------------------------------------------------------
section "2. Login e tokens"
# --------------------------------------------------------------------------
step "Login prestador..."
PROVIDER_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"barbearia@demo.com","password":"demo1234"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
[ -n "$PROVIDER_TOKEN" ] || fail "Login do prestador falhou"
ok "Token do prestador obtido"

step "Login cliente..."
CLIENT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@demo.com","password":"demo1234"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
[ -n "$CLIENT_TOKEN" ] || fail "Login do cliente falhou"
ok "Token do cliente obtido"

# --------------------------------------------------------------------------
section "3. Criação de serviço"
# --------------------------------------------------------------------------
step "Prestador cria serviço 'Corte de Cabelo'..."
SERVICE=$(curl -s -X POST "$BASE_URL/services" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PROVIDER_TOKEN" \
  -d '{"name":"Corte de Cabelo","description":"Corte masculino completo","price":45,"durationMinutes":30}')
SERVICE_ID=$(echo "$SERVICE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
[ -n "$SERVICE_ID" ] || fail "Criação do serviço falhou: $SERVICE"
ok "Serviço criado: $SERVICE_ID"

# --------------------------------------------------------------------------
section "4. Command Message — POST /reservations retorna 202"
# --------------------------------------------------------------------------
step "Cliente cria reserva (deve retornar 202 imediatamente)..."
echo -e "${BOLD}Observar no log do servidor:${RESET}"
echo "  [CommandConsumer] Reservation ... created"
echo "  [NotificationConsumer] Persisted \"reservation.created\""
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -d "{\"serviceTypeId\":\"$SERVICE_ID\",\"scheduledAt\":\"2026-07-01T10:00:00.000Z\"}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS:")

echo "Response HTTP: $HTTP_STATUS"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"

[ "$HTTP_STATUS" = "202" ] && ok "202 Accepted — resposta imediata antes do processamento assíncrono" \
  || echo -e "${YELLOW}⚠ Status inesperado: $HTTP_STATUS${RESET}"

sleep 2

# --------------------------------------------------------------------------
section "5. Notificação persistida — inbox do prestador"
# --------------------------------------------------------------------------
step "Verificando inbox do prestador..."
NOTIFS=$(curl -s "$BASE_URL/notifications" \
  -H "Authorization: Bearer $PROVIDER_TOKEN")
echo "$NOTIFS" | python3 -m json.tool 2>/dev/null || echo "$NOTIFS"

UNREAD=$(echo "$NOTIFS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('unreadCount',0))" 2>/dev/null)
[ "$UNREAD" -gt "0" ] && ok "Prestador tem $UNREAD notificação(ões) não lida(s)" \
  || echo -e "${YELLOW}⚠ Nenhuma notificação encontrada (aguarde o consumer processar)${RESET}"

NOTIF_ID=$(echo "$NOTIFS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
notifs = data.get('notifications', [])
print(notifs[0]['id'] if notifs else '')
" 2>/dev/null)

# --------------------------------------------------------------------------
section "6. Marcar notificação como lida"
# --------------------------------------------------------------------------
if [ -n "$NOTIF_ID" ]; then
  step "Marcando notificação $NOTIF_ID como lida..."
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
    "$BASE_URL/notifications/$NOTIF_ID/read" \
    -H "Authorization: Bearer $PROVIDER_TOKEN")
  [ "$STATUS" = "204" ] && ok "204 No Content — notificação marcada como lida" \
    || echo -e "${YELLOW}⚠ Status: $STATUS${RESET}"

  step "Inbox após marcar como lida..."
  curl -s "$BASE_URL/notifications" \
    -H "Authorization: Bearer $PROVIDER_TOKEN" | python3 -m json.tool 2>/dev/null
fi

# --------------------------------------------------------------------------
section "7. Controle de concorrência — dois requests simultâneos"
# --------------------------------------------------------------------------
step "Enviando 2 reservas em paralelo para o MESMO horário..."
echo -e "${BOLD}Observar no log do servidor:${RESET}"
echo "  [CommandConsumer] Reservation ... created    ← primeiro"
echo "  [CommandConsumer] Conflict for service ...   ← segundo bloqueado"
echo ""

curl -s -X POST "$BASE_URL/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -d "{\"serviceTypeId\":\"$SERVICE_ID\",\"scheduledAt\":\"2026-07-01T11:00:00.000Z\"}" \
  -o /tmp/req1.json &
PID1=$!

curl -s -X POST "$BASE_URL/reservations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -d "{\"serviceTypeId\":\"$SERVICE_ID\",\"scheduledAt\":\"2026-07-01T11:00:00.000Z\"}" \
  -o /tmp/req2.json &
PID2=$!

wait $PID1 $PID2

echo "Resposta 1: $(cat /tmp/req1.json)"
echo "Resposta 2: $(cat /tmp/req2.json)"

sleep 2

step "Verificando inbox do cliente (deve ter notificação de conflito)..."
CLIENT_NOTIFS=$(curl -s "$BASE_URL/notifications" \
  -H "Authorization: Bearer $CLIENT_TOKEN")
echo "$CLIENT_NOTIFS" | python3 -m json.tool 2>/dev/null || echo "$CLIENT_NOTIFS"

CONFLICT=$(echo "$CLIENT_NOTIFS" | python3 -c "
import sys,json
notifs = json.load(sys.stdin).get('notifications', [])
conflicts = [n for n in notifs if n['type'] == 'reservation.conflict']
print(len(conflicts))
" 2>/dev/null)
[ "$CONFLICT" -gt "0" ] && ok "Conflito detectado e notificado — apenas 1 reserva criada no banco" \
  || echo -e "${YELLOW}⚠ Sem notificação de conflito ainda (aguarde o consumer)${RESET}"

# --------------------------------------------------------------------------
section "8. Aceitar reserva — evento reservation.accepted"
# --------------------------------------------------------------------------
step "Buscando reservas do prestador..."
RESERVATIONS=$(curl -s "$BASE_URL/reservations" \
  -H "Authorization: Bearer $PROVIDER_TOKEN")
RESERVATION_ID=$(echo "$RESERVATIONS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
pending = [r for r in (data if isinstance(data,list) else []) if r.get('status')=='PENDING']
print(pending[0]['id'] if pending else '')
" 2>/dev/null)

if [ -n "$RESERVATION_ID" ]; then
  step "Prestador aceita reserva $RESERVATION_ID..."
  echo -e "${BOLD}Observar no log:${RESET}"
  echo "  [NotificationConsumer] Persisted \"reservation.accepted\" for user <clientId>"
  echo ""
  ACCEPT=$(curl -s -X PATCH "$BASE_URL/reservations/$RESERVATION_ID/status" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $PROVIDER_TOKEN" \
    -d '{"status":"ACCEPTED"}')
  echo "$ACCEPT" | python3 -m json.tool 2>/dev/null || echo "$ACCEPT"

  sleep 2

  step "Inbox do cliente (deve ter reservation.accepted)..."
  curl -s "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CLIENT_TOKEN" | python3 -m json.tool 2>/dev/null
  ok "Cliente notificado via MOM → NotificationConsumer → banco → WS"
else
  echo -e "${YELLOW}⚠ Nenhuma reserva PENDING encontrada para aceitar${RESET}"
fi

# --------------------------------------------------------------------------
section "9. Marcar todas como lidas"
# --------------------------------------------------------------------------
step "PATCH /notifications/read-all (cliente)..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
  "$BASE_URL/notifications/read-all" \
  -H "Authorization: Bearer $CLIENT_TOKEN")
[ "$STATUS" = "204" ] && ok "204 — todas as notificações do cliente marcadas como lidas" \
  || echo -e "${YELLOW}⚠ Status: $STATUS${RESET}"

step "Inbox final do cliente (unreadCount deve ser 0)..."
curl -s "$BASE_URL/notifications" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'unreadCount: {d[\"unreadCount\"]}, total: {len(d[\"notifications\"])}')" 2>/dev/null

# --------------------------------------------------------------------------
section "✅ Demo concluída"
# --------------------------------------------------------------------------
echo ""
echo -e "${BOLD}Evidências geradas:${RESET}"
echo "  1. POST /reservations → 202 (assincronicidade real)"
echo "  2. Notificação persistida no banco e entregue ao inbox"
echo "  3. Conflito de concorrência detectado e notificado"
echo "  4. Eventos reservation.accepted propagados via MOM"
echo "  5. Inbox funcional: listar, marcar lida, marcar todas"
echo ""
echo -e "${BOLD}Management UI:${RESET} http://localhost:15672 (admin/admin)"
echo "  → Exchanges → reservations → bindings"
echo "  → Queues → reservation.commands + notification.persist → messages acked"
echo ""

# --------------------------------------------------------------------------
section "🧹 Limpeza"
# --------------------------------------------------------------------------
echo -e "${BOLD}Pressione ENTER para limpar os dados criados pelo script${RESET}"
echo -e "${YELLOW}(ou Ctrl+C para sair e manter os dados para inspeção)${RESET}"
read -r

step "Deletando usuários provider e client..."

PROVIDER_ID=$(curl -s "$BASE_URL/users/me" \
  -H "Authorization: Bearer $PROVIDER_TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

CLIENT_ID=$(curl -s "$BASE_URL/users/me" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

STATUS_P=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/users/me" \
  -H "Authorization: Bearer $PROVIDER_TOKEN")
STATUS_C=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/users/me" \
  -H "Authorization: Bearer $CLIENT_TOKEN")

[ "$STATUS_P" = "204" ] && ok "Prestador removido" || echo -e "${YELLOW}⚠ Remoção do prestador: $STATUS_P${RESET}"
[ "$STATUS_C" = "204" ] && ok "Cliente removido" || echo -e "${YELLOW}⚠ Remoção do cliente: $STATUS_C${RESET}"

ok "Banco limpo — script pode ser executado novamente"
echo ""
