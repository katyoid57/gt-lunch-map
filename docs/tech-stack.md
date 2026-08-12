# 技術スタックと構成

市ヶ谷周辺の**ランチ／居酒屋**店リストを、アカウント不要で見られる **単一 HTML の地図ページ**にするプロジェクト。
`data/*.csv` を編集して `bash build.sh` すると `dist/index.html` が再生成される（これ単体で動く）。
設計判断の全経緯は `local/2026-08-11_ichigaya-lunch-map-handover.md`（引き継ぎ書）を参照。

## スタック一覧

| 層 | 採用技術 | 備考 |
|---|---|---|
| 地図ライブラリ | **Leaflet 1.9.4**（BSD-2-Clause） | HTML に埋め込み。実行時取得なし。既定マーカー画像／レイヤ画像に依存させない（`L.divIcon` の色＋1文字ラベル）ため **画像ファイル 0** で単一 HTML が成立 |
| 地図タイル | **地理院タイル（淡色 `pale`）** | **実行時の唯一の外部依存**。出典表示（`地理院タイル` リンク）を attribution に必須。標準タイルの切替は廃止（目に痛いため淡色固定） |
| 丁目境界 | **国土地理院住所 → LOA（uedayou）由来の GeoJSON** | `data/area_polygons.json` に埋め込み。エリアチップ hover 時の「丁目の縁取り」用 |
| 外部リンク | **Google Maps URLs（`maps/search`）** | API キー不要。店名＋市ヶ谷で店舗ページに着地。座標が無くてもリンクは機能。経路案内（`maps/dir`）は不要につき削除 |
| データ | **CSV（BOM 付き UTF-8）×2**（ランチ／居酒屋） | HTML に生テキストのまま `<script type="text/plain">` へ埋め込み、ブラウザ側 JS でパース（引用フィールド・先頭 BOM 対応）。両データセットを1つの HTML に同梱しトグルで切替 |
| ビルド | **bash + sed（GNU）+ curl** | node・python 不要。`sed` の `r`/`d` でプレースホルダへ流し込む。出力後にプレースホルダ残存を `grep` 検証 |
| 成果物 | **単一 HTML（`dist/index.html`）** | これ単体で動く。画像・別ファイル依存なし |
| 店の追加運用 | **skill `gt-add-lunch-store`**（`.claude/skills/`） | 調査→座標→評価質問→CSV追記→build を一気通貫。座標は Yahoo!マップ等の店舗ページから取得 |
| ホスティング（将来 / Phase 2） | GitHub Pages（`katyoid57`） | push・Pages 有効化は外向き操作。実行前に承認を取る |

## データ・スキーマ

- **2マップ・同一スキーマ**：ランチ＝`data/restaurants.csv`（ID `LU0xx`）／居酒屋＝`data/izakaya.csv`（ID `IZ0xx`）。
- 列（16）：`店舗ID,店名,カテゴリ,大分類,地域,住所,場所,lat,lng,訪問済,美味しさ,量,安さ,感想,備考,更新者`
  - 並び順は **識別 → 分類 → 場所 → 評価 → 記述 → メタ**。表示ロジックはヘッダ名で引く（`src/template.html` の `parseCSV` 後にオブジェクト化）ため、順序は表示に影響しない。
  - `地域`＝丁目（例 五番町）。`安さ`＝5=安い（お得）／1=高い。`大分類`＝色分けの基準（マップごとに別体系）。
  - `更新者` は**ニックネーム**（例 `katyoid`/`F`）。公開ページには一切表示しない。
- `大分類` はマップ別（`src/template.html` の `MAJORS_BY_DS`）。CSV の値と正式名が一致すると色＋1文字ラベルが付く。未記入・不一致は「その他」。
- **座標**は Yahoo!マップ等の店舗ページ由来（店舗ピンレベル）。GSI 住所検索は番地中心に丸められズレるため使わない。同一住所（同ビル）の店は表示だけ円状にずらす。

## 画面機能

- 左サイドバー（`«` で丸ごと収納）：ランチ⇄居酒屋トグル／地図・表トグル／検索／地域／ジャンル／訪問状態／評価下限（総合点・美味しさ・量・安さ）。
- 地図：淡色タイル、色＋1文字ラベルのピン、未訪問は破線。エリア/ジャンルチップ hover でピン強調（地域は丁目の縁取りも）。
- 右パネル：一覧（`»` で収納）。地図/表トグルで**同ページ内の表**（列見出しで並び替え）に切替。
- 総合点＝美味しさ・量・安さの平均。`<meta name="robots" content="noindex,nofollow">`。

## ファイル構成

```
data/restaurants.csv    ランチ正本（LU0xx）
data/izakaya.csv        居酒屋正本（IZ0xx）※同一スキーマ
data/area_polygons.json 丁目境界（hover 縁取り用）
src/template.html       テンプレート（HTML/CSS/JS 本体・プレースホルダ入り）
vendor/leaflet.{js,css} Leaflet 1.9.4（build.sh が無ければ取得しキャッシュ）
build.sh                ビルド（bash + sed）
dist/index.html         生成物。これ単体で動く
docs/tech-stack.md      このファイル
docs/coordinates.md     座標の入れ方
.claude/skills/gt-add-lunch-store/  店追加 skill（リポ同梱・配布可）
local/                  provenance（handover）・backlog ※gitignore
```

プレースホルダ差し込み（`build.sh`）：
- `<!--LEAFLET_CSS-->` / `<!--LEAFLET_JS-->` → `vendor/leaflet.{css,js}`
- `<!--CSV_DATA-->` → `data/restaurants.csv`（ランチ）
- `<!--IZAKAYA_DATA-->` → `data/izakaya.csv`（居酒屋）
- `<!--AREA_POLYGONS-->` → `data/area_polygons.json`

## ビルド・更新手順

```bash
bash build.sh          # → dist/index.html を生成（末尾の file://… をブラウザで開く）
```
- 店を足す：このリポで「◯◯を（ランチ/居酒屋）マップに追加して」→ skill `gt-add-lunch-store`。
- 手で編集する場合：対象 CSV を編集（BOM 付き UTF-8 維持）→ `bash build.sh`。

## なぜこの構成か（要点）

- 閲覧にアカウントを要求できない × 社内から Google 系（`docs.google.com`）が 403 × SharePoint/OneDrive は匿名不可 → データ置き場は社外、かつ **GitHub 一本**。
- Google Maps JS API はキー＋クレカ必須で公開ページに置けない → 地図描画は **Leaflet ＋ 地理院タイル**、Google へは**リンクで飛ばすだけ**。
- 実行時のデータ取得を設計上禁止 → **データも Leaflet 本体も HTML に埋め込む**。実行時に取りに行くのは地理院タイルだけ。
- 却下案（Power BI / Google マイマップ単体 / スプレッドシートをデータ源 / SharePoint に HTML 等）は引き継ぎ書 §2。**再提案しない。**

## 公開レディネス（後から GitHub Pages に載せられるか）

- ✅ 単一 HTML・相対パス依存なし（外部参照は絶対 HTTPS：地理院タイル・Google Maps のみ）。サブパス配下でも動く。
- ✅ Mixed content なし／サーバ処理不要（静的配信で完結）。
- ✅ `robots noindex,nofollow`／個人名・会社名・部署名・勤務地の明示なし。

Phase 2 で `dist/index.html` を GitHub Pages 配信（CSV push → build → deploy）。**リポ作成・push・Pages 有効化は外向き操作なので実行前に必ず承認を取る。**
