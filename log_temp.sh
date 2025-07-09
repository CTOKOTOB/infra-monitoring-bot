#!/bin/bash


set -a
source ~/infra-monitoring-bot/.env
set +a


# Получаем температуру CPU
TEMPERATURE=$(echo "scale=1; $(cat /sys/class/thermal/thermal_zone0/temp)/1000" | bc)

# SQL-запрос для вставки данных
SQL_QUERY="INSERT INTO temperature_logs (temperature, created_at) VALUES ($TEMPERATURE, NOW());"

# Выполняем запрос через psql
psql "$DATABASE_MONITORING_URL" -c "$SQL_QUERY"

