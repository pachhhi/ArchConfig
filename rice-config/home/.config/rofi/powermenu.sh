#!/usr/bin/env bash

choice=$(printf 'Lock\nLog out\nReboot\nPower off\n' | rofi -dmenu -i -p 'Power') || exit 0
case "$choice" in
  Lock) slock ;;
  'Log out') bspc quit ;;
  Reboot) systemctl reboot ;;
  'Power off') systemctl poweroff ;;
esac
