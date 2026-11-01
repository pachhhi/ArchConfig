#!/bin/sh

xrandr --dpi 110 2>/dev/null || true
export GTK_USE_PORTAL=1
export TERMINAL=kitty

case "${RICE_WM:-openbox}" in
  openbox) exec dbus-run-session openbox-session ;;
  bspwm) exec dbus-run-session bspwm ;;
  *) printf 'Unknown RICE_WM: %s (use openbox or bspwm)\n' "$RICE_WM" >&2; exit 2 ;;
esac
