#!/bin/bash

sleep 40


set -a
source ~/infra-monitoring-bot/.env
set +a


SQL_QUERY="
WITH latest_checks AS (
  SELECT DISTINCT ON (server_id)
    server_id, is_available, created_at
  FROM availability_checks
  ORDER BY server_id, created_at DESC
)
SELECT s.server_id, s.name, lc.created_at
FROM servers s
JOIN latest_checks lc ON lc.server_id = s.server_id
LEFT JOIN alerts a 
  ON a.server_id = s.server_id 
  AND a.created_at > now() - interval '15 minutes'
WHERE s.is_active = true AND lc.is_available = false AND a.alert_id IS NULL;
"

# Выполняем запрос
ALERTS=$(psql "$DATABASE_MONITORING_URL" -At -F',' -c "$SQL_QUERY")

if [[ -z "$ALERTS" ]]; then
    echo "[INFO] Нет алертов. Выход."
    exit 0
fi

# Читаем строки
while IFS=',' read -r SERVER_ID NAME TIMESTAMP; do
    if [[ -z "$SERVER_ID" || -z "$NAME" || -z "$TIMESTAMP" ]]; then
        echo "[WARN] Пропущена битая строка: $SERVER_ID | $NAME | $TIMESTAMP"
        continue
    fi

    MESSAGE="🚨 Сервер <b>${NAME}</b> недоступен! Время: ${TIMESTAMP}"

    # Добавление в alerts
    INSERT_QUERY="INSERT INTO alerts (server_id, metric_type, value, threshold, message)
                  VALUES ($SERVER_ID, 'availability', 0, 1, 'Server $NAME is DOWN');"
    psql "$DATABASE_MONITORING_URL" -c "$INSERT_QUERY"

    # Telegram отправка
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
         -d chat_id="$TELEGRAM_CHAT_ID" \
         --data-urlencode "text=$MESSAGE" \
         -d parse_mode="HTML"
done <<< "$ALERTS"


