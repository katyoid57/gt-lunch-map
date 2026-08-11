#!/usr/bin/env bash
# 対象マップのCSVに1行 append して build する。
#   usage: add_row.sh <lunch|izakaya> '<CSV1行ぶん(16列)>'
# BOM は先頭のみで触らない（append なので影響なし）。既存行は書き換えない。
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
case "${1:-}" in
  lunch)   csv="data/restaurants.csv";;
  izakaya) csv="data/izakaya.csv";;
  *) echo "usage: add_row.sh <lunch|izakaya> '<row>'" >&2; exit 1;;
esac
row="${2:-}"
[ -n "$row" ] || { echo "row is empty" >&2; exit 1; }

# 列数チェック（16列。カンマは引用フィールド内にも出るため厳密ではないが目安）
cols=$(awk -F',' '{print NF}' <<<"$row")
[ "$cols" -ge 16 ] || echo "  warn: 列数が $cols（16未満の可能性）。確認を。" >&2

# 末尾に改行が無ければ足してから append（BOM は先頭のみなので無関係）
[ -s "$csv" ] && [ "$(tail -c1 "$csv")" != "" ] && printf '\n' >> "$csv"
printf '%s\n' "$row" >> "$csv"
echo "  appended -> $csv"
bash build.sh
