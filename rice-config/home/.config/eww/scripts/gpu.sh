#!/usr/bin/env bash
# Read the first available DRM GPU utilization counter. No hardware-specific PCI path.
for metric in /sys/class/drm/card*/device/gpu_busy_percent; do
    [[ -r "$metric" ]] || continue
    IFS= read -r busy 2>/dev/null < "$metric" || continue
    case "$busy" in ''|*[!0-9]*) continue ;; esac
    if (( ${#busy} <= 3 )) && (( 10#$busy <= 100 )); then
        printf '%s\n' "$((10#$busy))"
        exit 0
    fi
done
printf 'N/A\n'
