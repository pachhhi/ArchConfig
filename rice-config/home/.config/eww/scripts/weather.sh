#!/bin/bash
# Requiere conexión a internet y curl + jq instalados.
# Devuelve JSON compacto: {"temp":"12°C","desc":"Few Clouds"}
# Si querés forzar tu ciudad en vez de detectarla por IP, cambiá la URL a:
#   curl -s "wttr.in/TuCiudad?format=j1"

data=$(curl -s --max-time 5 "wttr.in/?format=j1")

if [ -z "$data" ]; then
  echo '{"temp":"N/A","desc":"Sin conexión"}'
  exit 0
fi

echo "$data" | jq -c '{
  temp: (.current_condition[0].temp_C + "°C"),
  desc: .current_condition[0].weatherDesc[0].value
}'
