#!/usr/bin/env bash
# PCaC power and hardware utilization status (for Center)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null || true

echo "=== PCaC Power / Hardware Status ==="
echo "Time: $(date '+%H:%M:%S')"

# CPU
echo "--- CPU (5950X) ---"
GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "?")
FREQ=$(awk '{sum+=$1} END {printf "%.0f", sum/NR/1000}' /proc/cpuinfo 2>/dev/null || echo "?")
echo "Governor: $GOV | Avg freq: ${FREQ}MHz"
echo "Profile: $(powerprofilesctl get 2>/dev/null || echo 'N/A')"

# GPU AMD
echo "--- GPU (7900 XTX) ---"
if [ -d /sys/class/drm/card1/device ]; then
  PWR=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_average 2>/dev/null || echo 0)
  PWR_W=$((PWR / 1000000))
  LEVEL=$(cat /sys/class/drm/card1/device/power_dpm_force_performance_level 2>/dev/null || echo auto)
  echo "Power: ${PWR_W}W | Perf level: $LEVEL"
  echo " (Use corectrl for easy tuning/undervolt)"
else
  echo "No AMD GPU detected at card1"
fi

# LM / Brains
echo "--- LM Studio / Brains ---"
if curl -sfS --connect-timeout 1 http://127.0.0.1:1234/v1/models >/dev/null 2>&1; then
  echo "LM Studio: UP"
  MODELS=$(curl -s http://127.0.0.1:1234/v1/models | jq -r '.data[].id' 2>/dev/null | tr '\n' ' ')
  echo "Models: $MODELS"
else
  echo "LM Studio: DOWN (start server for Left/Right brains)"
fi

# Memory / Load (leverage 128GB)
echo "--- Memory / Load ---"
free -h | grep Mem
echo "Load avg: $(cat /proc/loadavg | cut -d' ' -f1-3)"

echo "Tips: powerprofilesctl set power-saver | balanced | performance"
echo "Install: paru -S corectrl (GUI for your 7900XTX)"
echo "For brains: use /ask-* in center-composer to leverage the hardware"
