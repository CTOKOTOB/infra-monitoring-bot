#!/bin/bash

sleep 5
# Загружаем переменные окружения
set -a
source ~/infra-monitoring-bot/.env
set +a

echo "[INFO] Запуск метрик-сборщика: $(date)"

TMP_DIR="/tmp/infra_monitoring"
INVENTORY_FILE="$TMP_DIR/inventory.ini"
PLAYBOOK_FILE="$TMP_DIR/collect_metrics.yml"
RAW_CSV="$TMP_DIR/servers_raw.csv"
METRICS_DIR="$TMP_DIR/server_metrics"

mkdir -p "$TMP_DIR"
mkdir -p "$METRICS_DIR"

# 1. Получаем список серверов с SSH-портом != 22
echo "[INFO] Формируем inventory.ini"

psql "$DATABASE_MONITORING_URL" -At -F',' -c "
SELECT name, ip_address, ssh_port, connect_user, connect_password_enc
FROM servers
WHERE is_active = true AND ssh_port != 22;
" > "$RAW_CSV"

echo "[ubuntu]" > "$INVENTORY_FILE"
while IFS=',' read -r NAME IP PORT USER ENC_PASS; do
  if [[ -n "$ENC_PASS" ]]; then
    PASS=$(echo "$ENC_PASS" | openssl enc -aes-256-cbc -a -d -salt -pbkdf2 -pass pass:"$ENCRYPTION_KEY" 2>/dev/null)
    echo "$NAME ansible_host=$IP ansible_port=$PORT ansible_user=$USER ansible_ssh_pass=$PASS ansible_become_pass=$PASS" >> "$INVENTORY_FILE"
  else
    echo "$NAME ansible_host=$IP ansible_port=$PORT ansible_user=$USER" >> "$INVENTORY_FILE"
  fi
done < "$RAW_CSV"

# 2. Ansible playbook
echo "[INFO] Создаём Ansible playbook"

cat > "$PLAYBOOK_FILE" <<EOF
---
- name: Collect system metrics
  hosts: ubuntu
  gather_facts: false
  tasks:
    - name: Install required packages
      apt:
        name:
          - bc
          - coreutils
        state: present
        update_cache: yes
      become: true

    - name: Collect CPU, RAM, and Disk usage
      shell: |
        CPU=\$(top -bn1 | grep 'Cpu(s)' | awk -F',' '{for (i=1;i<=NF;i++) if (\$i ~ /id/) print \$i}' | awk '{print 100 - \$1}')
        RAM_TOTAL=\$(free -m | awk '/Mem:/ {print \$2}')
        RAM_USED=\$(free -m | awk '/Mem:/ {print \$3}')
        DISK_TOTAL=\$(df -m / | awk 'END {print \$2}')
        DISK_USED=\$(df -m / | awk 'END {print \$3}')
        DISK_PCT=\$(df / | awk 'END {print \$5}' | tr -d '%')
        echo "{
          \\"cpu\\": \$CPU,
          \\"ram_total\\": \$RAM_TOTAL,
          \\"ram_used\\": \$RAM_USED,
          \\"ram_pct\\": \$((\$RAM_USED * 100 / \$RAM_TOTAL)),
          \\"disk_total\\": \$DISK_TOTAL,
          \\"disk_used\\": \$DISK_USED,
          \\"disk_pct\\": \$DISK_PCT
        }" > /tmp/server_metrics.json
      become: true

    - name: Fetch metrics file
      fetch:
        src: /tmp/server_metrics.json
        dest: "$METRICS_DIR/{{ inventory_hostname }}.json"
        flat: true
EOF

# 3. Запуск Ansible
echo "[INFO] Запускаем Ansible"
ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE"

echo "[INFO] Метрики собраны в $METRICS_DIR"

# 4. Загрузка в PostgreSQL
echo "[INFO] Загружаем метрики в базу данных..."

for FILE in "$METRICS_DIR"/*.json; do
  SERVER_NAME=$(basename "$FILE" .json)

  # Получаем server_id
  SERVER_ID=$(psql "$DATABASE_MONITORING_URL" -At -c "SELECT server_id FROM servers WHERE name = '$SERVER_NAME';")

  if [[ -z "$SERVER_ID" ]]; then
    echo "[WARN] Не найден server_id для $SERVER_NAME"
    continue
  fi

  # Извлекаем метрики
  CPU=$(jq '.cpu' "$FILE")
  RAM_TOTAL_MB=$(jq '.ram_total' "$FILE")
  RAM_USED_MB=$(jq '.ram_used' "$FILE")
  RAM_PCT=$(jq '.ram_pct' "$FILE")
  DISK_TOTAL_MB=$(jq '.disk_total' "$FILE")
  DISK_USED_MB=$(jq '.disk_used' "$FILE")
  DISK_PCT=$(jq '.disk_pct' "$FILE")

  # Перевод в GB
  RAM_TOTAL_GB=$(echo "scale=2; $RAM_TOTAL_MB / 1024" | bc)
  RAM_USED_GB=$(echo "scale=2; $RAM_USED_MB / 1024" | bc)
  DISK_TOTAL_GB=$(echo "scale=2; $DISK_TOTAL_MB / 1024" | bc)
  DISK_USED_GB=$(echo "scale=2; $DISK_USED_MB / 1024" | bc)

  # Вставка CPU
  psql "$DATABASE_MONITORING_URL" -c "
    INSERT INTO cpu_usage (server_id, load_1m, load_5m, load_15m, cpu_percent)
    VALUES ($SERVER_ID, 0, 0, 0, $CPU);
  "

  # Вставка RAM
  psql "$DATABASE_MONITORING_URL" -c "
    INSERT INTO ram_usage (server_id, total_gb, used_gb, used_percent)
    VALUES ($SERVER_ID, $RAM_TOTAL_GB, $RAM_USED_GB, $RAM_PCT);
  "

  # Вставка диска
  psql "$DATABASE_MONITORING_URL" -c "
    INSERT INTO disk_usage (server_id, mount_point, total_gb, used_gb, used_percent)
    VALUES ($SERVER_ID, '/', $DISK_TOTAL_GB, $DISK_USED_GB, $DISK_PCT);
  "

  echo "[INFO] Метрики для $SERVER_NAME ($SERVER_ID) загружены."
done

# === Добавляем локальный сбор метрик ===

echo "[INFO] Сбор метрик с локального хоста..."

# Получаем server_id локального сервера (предполагается, что в таблице servers есть запись с name = 'raspberry_pi')
local_server_id=$(psql "$DATABASE_MONITORING_URL" -t -c "SELECT server_id FROM servers WHERE name = 'raspberry_pi';" | tr -d ' ')

if [[ -z "$local_server_id" ]]; then
  echo "[ERROR] Не найден server_id для raspberry_pi в базе. Добавьте запись в таблицу servers."
  exit 1
fi

# Собираем метрики локально
load_1m=$(cut -d ' ' -f1 /proc/loadavg)
load_5m=$(cut -d ' ' -f2 /proc/loadavg)
load_15m=$(cut -d ' ' -f3 /proc/loadavg)

cpu_idle=$(top -bn1 | grep 'Cpu(s)' | awk '{print $8}' | tr -d ',')
cpu_percent=$(echo "100 - $cpu_idle" | bc)

ram_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ram_available_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
ram_used_kb=$((ram_total_kb - ram_available_kb))
ram_used_percent=$(echo "scale=1; $ram_used_kb / $ram_total_kb * 100" | bc)

ram_total_gb=$(echo "scale=2; $ram_total_kb / 1024 / 1024" | bc)
ram_used_gb=$(echo "scale=2; $ram_used_kb / 1024 / 1024" | bc)

disk_stats=$(df / | tail -1)
disk_total_gb=$(echo "$disk_stats" | awk '{print $2}')
disk_used_gb=$(echo "$disk_stats" | awk '{print $3}')
disk_used_percent=$(echo "$disk_stats" | awk '{print $5}' | tr -d '%')

disk_total_gb=$(echo "scale=2; $disk_total_gb / 1024 / 1024" | bc)
disk_used_gb=$(echo "scale=2; $disk_used_gb / 1024 / 1024" | bc)

# Вставляем в базу
psql "$DATABASE_MONITORING_URL" -c "
INSERT INTO cpu_usage (server_id, load_1m, load_5m, load_15m, cpu_percent) 
VALUES ($local_server_id, $load_1m, $load_5m, $load_15m, $cpu_percent);
"

psql "$DATABASE_MONITORING_URL" -c "
INSERT INTO ram_usage (server_id, total_gb, used_gb, used_percent)
VALUES ($local_server_id, $ram_total_gb, $ram_used_gb, $ram_used_percent);
"

psql "$DATABASE_MONITORING_URL" -c "
INSERT INTO disk_usage (server_id, mount_point, total_gb, used_gb, used_percent)
VALUES ($local_server_id, '/', $disk_total_gb, $disk_used_gb, $disk_used_percent);
"

echo "[INFO] Метрики для raspberry_pi ($local_server_id) загружены."

rm -rf $TMP_DIR

