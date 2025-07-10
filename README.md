# infra-monitoring-bot

The idea is to collect network latency metrics from my VPS instances and OpenWRT-configured routers on a local Raspberry Pi and store them in a PostgreSQL database. If any of the devices become unreachable, a Telegram notification should be sent.

crontab

* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/log_temp.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/check_servers.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/check_alerts.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/server_metrics.sh 2>&1


