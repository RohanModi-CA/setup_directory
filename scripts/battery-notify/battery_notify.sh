#!/usr/bin/bash

CURRENT_BATTERY=$(acpi -b | grep -oP '[0-9]+(?=%)')
NOT_CHARGING=$(acpi -b | grep -q "Charging"; echo $?)

BATTERY_WARN_COMMAND="notify-send -t 7000 -u critical -i battery \"Don't let me die.\" -h string:fgcolor:#FFFFFF -h string:bgcolor:#FF0000 \"<big>Low Battery</big>\""



if [[ "$CURRENT_BATTERY" -lt 11 && "$NOT_CHARGING" -eq 1 ]];
then
	eval "$BATTERY_WARN_COMMAND"
fi


