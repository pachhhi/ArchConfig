#!/usr/bin/env bash
set -u

target="$1"
action="$2"
id="${3:-}"
value="${4:-}"

case "$action" in
  up)   pactl set-${target}-volume "$id" +5% ;;
  down) pactl set-${target}-volume "$id" -5% ;;
  mute) pactl set-${target}-mute "$id" toggle ;;
  set)  pactl set-${target}-volume "$id" "${value}%" ;;
  default) pactl set-default-sink "$id" ;;
esac
