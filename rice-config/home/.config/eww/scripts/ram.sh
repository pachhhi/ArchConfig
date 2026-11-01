#!/bin/bash
# % de RAM usada (excluye cache/buffers, usa la columna "used" real de free)
free | awk '/^Mem:/ {printf "%.0f", ($3/$2) * 100}'
