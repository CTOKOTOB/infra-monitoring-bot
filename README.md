# infra-monitoring-bot
Telegram bot for infrastructure monitoring (Raspberry Pi, servers, etc.)


crontab

* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/log_temp.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/check_servers.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/check_alerts.sh 2>&1


