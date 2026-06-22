# Bharat Herald DX分析 改善版

この改善版では、元の英語プロジェクトを残したまま、SQLによる深層データクリーニングと日本語HTMLレポート生成を追加しました。

## 追加内容

- `improved_sql_jp/01_deep_data_cleaning.sql`
  - 日語コメント付きのSQLite SQL
  - 日付、通貨、都市名、州名、広告カテゴリを標準化
  - 返品率、印刷効率、Pilot反応率、アクセス単価、DX優先度スコアを作成
  - 異常値フラグと分析用ビューを作成

- `scripts/build_clean_db.py`
  - `New Datasets/` のCSVをSQLiteへ読み込み
  - SQLクリーニングを実行
  - `improved_outputs/bharat_herald_cleaned.sqlite` を生成

- `scripts/generate_japanese_report.py`
  - 清理済みDBから日本語HTMLレポートを生成
  - SVGグラフをHTML内に直接描画
  - pandas/matplotlibなしで実行可能

## 実行方法

```powershell
python scripts/build_clean_db.py
python scripts/generate_japanese_report.py
```

生成物:

- `improved_outputs/bharat_herald_cleaned.sqlite`
- `improved_outputs/bharat_herald_dx_report_jp.html`

## 分析上の改善点

1. 広告収入の通貨をINRへ統一
2. `May-23`、`2023-Q2`、`Q1-2019`、`4th Qtr 2020` などの日付表記を統一
3. 都市名・州名の大小文字と表記ゆれを統一
4. 印刷事業の返品率・効率・月次落ち込みを追加
5. DX準備度とPilot実績のギャップから優先都市を可視化

## GitHub公開手順

このPCには `gh` CLI がないため、GitHub上で空リポジトリを作った後、以下を実行してください。

```powershell
git remote add origin https://github.com/<your-account>/<repo-name>.git
git branch -M main
git push -u origin main
```
