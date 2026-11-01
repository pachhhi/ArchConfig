#!/bin/bash
# TODO: personalizá esto según cómo manejes tus temas.
# Ejemplos posibles:
#   - Cambiar el wallpaper con feh/nitrogen a una variante clara/oscura
#   - Cambiar el <name> del <theme> en tu openbox rc.xml y recargar
#   - Alternar variante de tu barra (polybar) o picom
#
# Por ahora solo togglea un archivo de estado como ejemplo.
STATE_FILE="/tmp/eww-theme-state"

if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "dark" ]; then
  echo "light" > "$STATE_FILE"
  echo "TODO: aplicar tema claro"
else
  echo "dark" > "$STATE_FILE"
  echo "TODO: aplicar tema oscuro"
fi
