#!/usr/bin/env bash
# 対象マップの次の店舗IDを出力する（例: LU046 / IZ002）
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
case "${1:-}" in
  lunch)   csv="data/restaurants.csv"; p="LU";;
  izakaya) csv="data/izakaya.csv";     p="IZ";;
  *) echo "usage: next_id.sh <lunch|izakaya>" >&2; exit 1;;
esac
n=$(grep -oE "^${p}[0-9]{3}" "$csv" 2>/dev/null | sed "s/${p}//" | sort -n | tail -1)
n=${n:-0}
printf '%s%03d\n' "$p" $((10#$n + 1))
