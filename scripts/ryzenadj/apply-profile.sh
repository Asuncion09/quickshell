#!/bin/bash
# Script unificado para alternar perfiles de energía (PPD + RyzenAdj)
PROFILE="$1"

case "$PROFILE" in
  "power-save"|"power-saver")
    # 1. Aplicar perfil de kernel (PPD)
    if command -v powerprofilesctl >/dev/null 2>&1; then
      powerprofilesctl set power-saver >/dev/null 2>&1
    fi
    # 2. Aplicar límites de hardware en silicio (RyzenAdj)
    if [ -x /usr/local/bin/ryzenadj-power-save.sh ]; then
      sudo -n /usr/local/bin/ryzenadj-power-save.sh >/dev/null 2>&1 || true
    fi
    echo "power-saver"
    ;;

  "balanced")
    # 1. Aplicar perfil de kernel (PPD)
    if command -v powerprofilesctl >/dev/null 2>&1; then
      powerprofilesctl set balanced >/dev/null 2>&1
    fi
    # 2. Aplicar límites de hardware en silicio (RyzenAdj)
    if [ -x /usr/local/bin/ryzenadj-balanced.sh ]; then
      sudo -n /usr/local/bin/ryzenadj-balanced.sh >/dev/null 2>&1 || true
    fi
    echo "balanced"
    ;;

  "performance"|"gaming")
    # 1. Aplicar perfil de kernel (PPD) - Si la plataforma no expone 'performance', recurrir a 'balanced'
    if command -v powerprofilesctl >/dev/null 2>&1; then
      powerprofilesctl set performance >/dev/null 2>&1 || powerprofilesctl set balanced >/dev/null 2>&1
    fi
    # 2. Aplicar límites de hardware en silicio (RyzenAdj)
    if [ -x /usr/local/bin/ryzenadj-gaming.sh ]; then
      sudo -n /usr/local/bin/ryzenadj-gaming.sh >/dev/null 2>&1 || true
    fi
    echo "performance"
    ;;

  *)
    echo "Uso: $0 {power-save|balanced|performance}"
    exit 1
    ;;
esac
