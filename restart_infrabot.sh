#!/bin/bash

#37 */4 * * * sh  /usr/bin/bash /home/dim/infra-monitoring-bot/restart_infrabot.sh

SERVICE_NAME="infra-monitoring-bot"

if systemctl is-active --quiet "$SERVICE_NAME"; then sudo /usr/bin/systemctl restart "$SERVICE_NAME"; else exit 0; fi

