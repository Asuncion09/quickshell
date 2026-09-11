#!/bin/bash
# RyzenAdj Balanced Profile - Sweet Spot de eficiencia para uso diario
/usr/local/bin/ryzenadj \
  --fast-limit=32000 \
  --slow-limit=28000 \
  --stapm-limit=25000 \
  --tctl-temp=80
