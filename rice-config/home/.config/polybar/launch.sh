#!/usr/bin/env bash

killall -q polybar
while pgrep -x polybar >/dev/null 2>&1; do sleep 0.2; done

POLYBAR_NETWORK_INTERFACE=${POLYBAR_NETWORK_INTERFACE:-$(ip -o route show default 2>/dev/null | awk 'NR == 1 {print $5}')}
if [[ -z "$POLYBAR_NETWORK_INTERFACE" ]]; then
  POLYBAR_NETWORK_INTERFACE=$(ip -o link show 2>/dev/null | awk -F ': ' '$2 ~ /^(en|wl|eth|wlan)/ {print $2; exit}')
fi
export POLYBAR_NETWORK_INTERFACE=${POLYBAR_NETWORK_INTERFACE:-lo}

polybar main &
