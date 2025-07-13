
#!/bin/bash

set -a
source ~/infra-monitoring-bot/.env
source ~/infra-monitoring-bot/.env_db
set +a

v_date=$(date +%Y%m%d%H%M%S)
d_backup="/backups"
#mkdir -p "$d_backup"

message="📦 <b>PostgreSQL Backup Report</b>%0A"

# Пройтись по переменным DB_ENTRY_*
for entry in $(compgen -A variable DB_ENTRY_); do
    IFS='|' read -r name host port dbname user <<< "${!entry}"
    file="${d_backup}/${dbname}_${v_date}.sql.gz"

    if pg_dump -h "$host" -p "$port" -U "$user" "$dbname" | gzip > "$file"; then
        message+="✅ <b>${name}</b>: backup created: <code>$(basename "$file")</code>%0A"
    else
        message+="❌ <b>${name}</b>: backup FAILED%0A"
        rm -f "$file"
        continue
    fi

        global_file="${d_backup}/global_objects_${name}_${v_date}.sql"
        if pg_dumpall -h "$host" -p "$port" -U "$user" -g > "$global_file"; then
            message+="🔐 Global objects backup created: <code>$(basename "$global_file")</code>%0A"
        else
            message+="❌ Global objects backup FAILED\n"
            rm -f "$global_file"
        fi

done

# Удаление старых бэкапов
deleted=$(find "$d_backup" -type f -mtime +7)
if [ -n "$deleted" ]; then
    message+="🗑️ <b>Deleted old backups:</b>%0A"
    while IFS= read -r file; do
        message+="• $(basename "$file")%0A"
        rm -f "$file"
    done <<< "$deleted"
fi


# Telegram уведомление
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
	-d chat_id="$TELEGRAM_CHAT_ID" \
	-d "text=$message" \
	-d parse_mode="HTML"


# содержимое .env_db
# Пример строки: NAME|HOST|PORT|DBNAME|USER
# DB_ENTRY_2="analytics|192.168.0.100|5433|analytics_db|analytics_user"

