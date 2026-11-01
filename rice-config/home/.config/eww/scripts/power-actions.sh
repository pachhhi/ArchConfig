#!/bin/bash
# Uso: power-actions.sh poweroff|reboot|lock|logout
#
# NOTA: "lock" usa "slock" por defecto (Arch: sudo pacman -S slock).
# Si usás otro (i3lock, betterlockscreen, xautolock), cambiá esa línea.
# "logout" mata openbox — ajustalo si usás un session manager distinto.

action="$1"
eww close launcher-window

case "$action" in
  poweroff) systemctl poweroff ;;
  reboot)   systemctl reboot ;;
  lock)     slock ;;
  logout)   pkill -x openbox ;;
esac
