#!/usr/bin/env bash
# 市ヶ谷ランチマップ ビルドスクリプト
#   CSV + Leaflet + テンプレート → 単一 HTML（データ・ライブラリを埋め込み）
#   依存：bash / sed（GNU） / curl のみ（node・python 不要）
set -euo pipefail

cd "$(dirname "$0")"

LEAFLET_VER="1.9.4"
TEMPLATE="src/template.html"
CSV="data/restaurants.csv"
IZCSV="data/izakaya.csv"
POLY="data/area_polygons.json"
VENDOR="vendor"
OUT_DIR="dist"
OUT="$OUT_DIR/index.html"

# --- 1. Leaflet を取得（無ければ unpkg からダウンロードしてキャッシュ） ---
mkdir -p "$VENDOR"
fetch() {
  local url="$1" dest="$2"
  if [ -s "$dest" ]; then
    echo "  cache : $dest"
  else
    echo "  fetch : $url"
    curl -fsSL "$url" -o "$dest"
  fi
}
echo "[1/4] Leaflet $LEAFLET_VER を用意"
fetch "https://unpkg.com/leaflet@${LEAFLET_VER}/dist/leaflet.css" "$VENDOR/leaflet.css"
fetch "https://unpkg.com/leaflet@${LEAFLET_VER}/dist/leaflet.js"  "$VENDOR/leaflet.js"

# --- 2. プレースホルダに中身を流し込む（sed の r/d でエスケープ事故ゼロ） ---
# r file : マッチ行の後にファイル内容をそのまま出力 / d : マッチ行自体を削除
echo "[2/4] テンプレートへ埋め込み"
mkdir -p "$OUT_DIR"
sed -e "/<!--LEAFLET_CSS-->/{r $VENDOR/leaflet.css" -e "d}" "$TEMPLATE" \
  | sed -e "/<!--LEAFLET_JS-->/{r $VENDOR/leaflet.js" -e "d}" \
  | sed -e "/<!--CSV_DATA-->/{r $CSV" -e "d}" \
  | sed -e "/<!--IZAKAYA_DATA-->/{r $IZCSV" -e "d}" \
  | sed -e "/<!--AREA_POLYGONS-->/{r $POLY" -e "d}" \
  > "$OUT"

# --- 3. プレースホルダが残っていないか検証（残っていたら失敗） ---
echo "[3/4] 埋め込み検証"
if grep -qE '<!--(LEAFLET_CSS|LEAFLET_JS|CSV_DATA|IZAKAYA_DATA|AREA_POLYGONS)-->' "$OUT"; then
  echo "  ERROR: プレースホルダが残っています" >&2
  grep -nE '<!--(LEAFLET_CSS|LEAFLET_JS|CSV_DATA|IZAKAYA_DATA|AREA_POLYGONS)-->' "$OUT" >&2
  rm -f "$OUT"
  exit 1
fi

# --- 4. 完了サマリ ---
echo "[4/4] 完了"
BYTES=$(wc -c < "$OUT" | tr -d ' ')
ROWS=$(( $(grep -c '^LU[0-9]' "$CSV") ))
echo "  出力 : $OUT (${BYTES} bytes)"
echo "  データ: ${ROWS} 件"
echo "  ブラウザで開く: file://$(pwd)/$OUT"
