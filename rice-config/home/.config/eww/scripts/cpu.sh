#!/bin/bash
# Calcula el % de uso de CPU comparando dos lecturas de /proc/stat
# separadas por 0.4s. No depende de paquetes extra (mpstat, etc).

read -r _ u1 n1 s1 i1 io1 irq1 sirq1 st1 _ < /proc/stat
total1=$((u1 + n1 + s1 + i1 + io1 + irq1 + sirq1 + st1))
idle1=$i1

sleep 0.4

read -r _ u2 n2 s2 i2 io2 irq2 sirq2 st2 _ < /proc/stat
total2=$((u2 + n2 + s2 + i2 + io2 + irq2 + sirq2 + st2))
idle2=$i2

total_diff=$((total2 - total1))
idle_diff=$((idle2 - idle1))

if [ "$total_diff" -eq 0 ]; then
  echo 0
else
  echo $(( (1000 * (total_diff - idle_diff) / total_diff + 5) / 10 ))
fi
