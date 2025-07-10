# infra-monitoring-bot

The idea is to collect network latency metrics from my VPS instances and OpenWRT-configured routers on a local Raspberry Pi and store them in a PostgreSQL database. If any of the devices become unreachable, a Telegram notification should be sent.

crontab -l
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/log_temp.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/check_servers.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/check_alerts.sh 2>&1
* * * * * /usr/bin/bash /home/dim/infra-monitoring-bot/server_metrics.sh 2>&1

cat .bash_aliases
alias psql='sudo -u postgres psql -d monitoring_db'
alias postgreslog="tail -100f /var/log/postgresql/postgresql-17-main.log"
alias activate='cd /home/dim/infra-monitoring-bot && source venv/bin/activate'
alias stopbot='sudo systemctl stop infra-monitoring-bot'
alias startbot='sudo systemctl start infra-monitoring-bot'
alias statusbot='sudo systemctl status infra-monitoring-bot'
alias logbot="journalctl -u infra-monitoring-bot -f"

commands:
temp - cpu pi
graph - график cpu pi
status - отклик по серверам
serv_detail - метрики по конкретному серверу
