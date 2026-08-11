# 市ヶ谷ランチ／居酒屋マップ

市ヶ谷周辺のランチ・居酒屋を、**アカウント不要**で見られる**単一 HTML の地図ページ**にするプロジェクト。
`data/*.csv` を編集して `bash build.sh` すると `dist/index.html` が再生成される（これ単体で動く）。

## 使い方

```bash
bash build.sh          # → dist/index.html を生成
```
- 開く：ブラウザで `dist/index.html`（地図タイルの表示だけ社内ネットワーク＝地理院サーバ到達が必要）。
- 画面：左サイドバーで **ランチ⇄居酒屋** と **地図⇄表** を切替。検索／地域／ジャンル／訪問状態／評価下限で絞り込み。
- **店を足す**：このリポで「◯◯を（ランチ/居酒屋）マップに追加して」と頼むと、skill `gt-add-lunch-store` が調査→座標→評価の質問→CSV追記→build まで実施する。

## 構成

```
data/restaurants.csv    ランチ正本（LU0xx）
data/izakaya.csv        居酒屋正本（IZ0xx）※同一スキーマ
data/area_polygons.json 丁目境界（hover 縁取り用）
src/template.html       テンプレート（HTML/CSS/JS 本体）
build.sh                ビルド（bash + sed）
dist/index.html         生成物
vendor/leaflet.*        Leaflet 1.9.4
docs/                   技術スタック・座標の手順
.claude/skills/gt-add-lunch-store/  店追加 skill（リポ同梱）
```

## ドキュメント

- 技術スタックと構成 … `docs/tech-stack.md`
- 座標の入れ方 … `docs/coordinates.md`
- 設計の経緯（provenance）… `local/2026-08-11_ichigaya-lunch-map-handover.md`
- 今後やりたいこと … `local/backlog.md`

## 方針（重要）

- 実行時に外部から取るのは**地理院タイルのみ**。Leaflet 本体もデータも HTML に埋め込む。
- 公開ページに**個人名・会社名・部署名・勤務地を出さない**（更新者はニックネーム／`robots noindex`）。
- **push / Pages 公開は外向き操作**。実行前に必ず承認を取る（Phase 2）。
