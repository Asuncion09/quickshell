#!/bin/bash
# RyzenAdj Gaming Profile - Máximo rendimiento balanceado para evitar thermal throttling
/usr/local/bin/ryzenadj \
  --fast-limit=42000 \
  --slow-limit=35000 \
  --stapm-limit=32000 \
  --tctl-temp=85
