#!/bin/bash
# RyzenAdj Power Save Profile - Máxima duración de batería y silencio térmico
/usr/local/bin/ryzenadj \
  --fast-limit=18000 \
  --slow-limit=15000 \
  --stapm-limit=12000 \
  --tctl-temp=70
