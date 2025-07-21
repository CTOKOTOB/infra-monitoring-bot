#!/bin/bash


set -a
source ~/infra-monitoring-bot/.env
set +a

pidfile="/tmp/$(basename -- "${BASH_SOURCE[0]}").pid"

if [[ -f "$pidfile" ]]; then
    pid=$(cat "$pidfile")
    if [[ "$pid" =~ ^[0-9]+$ ]] && [[ -e "/proc/$pid" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") [WARNING] $(hostname -s) - $(basename "$0") already running (PID $pid)"
        exit 1
    fi
fi

echo "$$" > "$pidfile"
trap 'rm -f "$pidfile"' EXIT


# Получаем список активных серверов
#SERVERS=$(psql "$DATABASE_MONITORING_URL" -Atc "SELECT server_id, ip_address, ssh_port FROM servers WHERE is_active = true;")
SERVERS=$(psql "$DATABASE_MONITORING_URL" -Atc "SELECT server_id, ip_address, ssh_port FROM servers WHERE is_active = true and name != 'raspberry_pi';")

# Обрабатываем каждый сервер
echo "$SERVERS" | while IFS='|' read -r SERVER_ID IP PORT; do
    START=$(date +%s%3N)

    # Пробуем подключиться
    OUTPUT=$(timeout 2 nc -zv "$IP" "$PORT" 2>&1)
    EXIT_CODE=$?

    END=$(date +%s%3N)
    ELAPSED_MS=$((END - START))
    ELAPSED_SEC=$(echo "scale=3; $ELAPSED_MS / 1000" | bc)

    if [ $EXIT_CODE -eq 0 ]; then
        IS_AVAILABLE=true
        ERROR_MSG="NULL"
    else
        IS_AVAILABLE=false
        # Экранируем кавычки
        ERROR_MSG="'$(echo "$OUTPUT" | sed "s/'/''/g")'"
    fi

    # Вставляем результат в БД
    SQL_QUERY="INSERT INTO availability_checks (server_id, is_available, response_time, error_message, created_at)
               VALUES ($SERVER_ID, $IS_AVAILABLE, $ELAPSED_SEC, $ERROR_MSG, NOW());"

    psql "$DATABASE_MONITORING_URL" -c "$SQL_QUERY"

done

