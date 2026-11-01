#!/bin/bash
# Devuelve una frase corta. Usa "fortune" si está instalado
# (Arch: sudo pacman -S fortune-mod), si no cae a una lista fija.

if command -v fortune &>/dev/null; then
  fortune -s | tr '\n' ' ' | sed 's/  */ /g'
  exit 0
fi

frases=(
  "Wisdom begins in wonder. — Socrates"
  "The only true wisdom is in knowing you know nothing. — Socrates"
  "He who has a why to live can bear almost any how. — Nietzsche"
)
echo "${frases[$RANDOM % ${#frases[@]}]}"
