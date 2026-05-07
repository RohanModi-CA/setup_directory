#!/usr/bin/env bash

current_audio_out=$(wpctl status | grep -A 2 "Sinks:" | grep "*" | sed 's/^.*\* *[0-9]*\. \(.*\) \[vol:.*$/\1/' | xargs)

if [[ "$current_audio_out" = "Built-in Audio Stéréo analogique" ]]; then
	current_audio_out=$(pactl list sinks | grep "Port actif" | cut -d " " -f 3 | awk -F'-' '{print toupper(substr($NF,1,1)) substr($NF,2)}')
fi

echo $current_audio_out
