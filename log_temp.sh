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


# Получаем температуру CPU
TEMPERATURE=$(echo "scale=1; $(cat /sys/class/thermal/thermal_zone0/temp)/1000" | bc)

# SQL-запрос для вставки данных
SQL_QUERY="INSERT INTO temperature_logs (temperature, created_at) VALUES ($TEMPERATURE, NOW());"

# Выполняем запрос через psql
psql "$DATABASE_MONITORING_URL" -c "$SQL_QUERY"

