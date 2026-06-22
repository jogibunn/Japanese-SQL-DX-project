"""清理済みSQLiteデータから日本語HTMLレポートを生成する。"""

from __future__ import annotations

import html
import sqlite3
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "improved_outputs" / "bharat_herald_cleaned.sqlite"
REPORT_PATH = ROOT / "improved_outputs" / "bharat_herald_dx_report_jp.html"


def query(conn: sqlite3.Connection, sql: str, params: tuple = ()) -> list[sqlite3.Row]:
    return conn.execute(sql, params).fetchall()


def yen(value: float | int | None) -> str:
    if value is None:
        return "-"
    if abs(float(value)) >= 100_000_000:
        return f"{float(value) / 100_000_000:.2f}億INR"
    if abs(float(value)) >= 10_000:
        return f"{float(value) / 10_000:.1f}万INR"
    return f"{float(value):,.0f}INR"


def num(value: float | int | None, suffix: str = "") -> str:
    if value is None:
        return "-"
    return f"{float(value):,.2f}{suffix}".rstrip("0").rstrip(".")


def esc(value: object) -> str:
    return html.escape("" if value is None else str(value))


def table(rows: list[sqlite3.Row], columns: list[tuple[str, str]], limit: int | None = None) -> str:
    use_rows = rows if limit is None else rows[:limit]
    head = "".join(f"<th>{esc(label)}</th>" for _, label in columns)
    body = []
    for row in use_rows:
        cells = "".join(f"<td>{esc(row[key])}</td>" for key, _ in columns)
        body.append(f"<tr>{cells}</tr>")
    return f"<table><thead><tr>{head}</tr></thead><tbody>{''.join(body)}</tbody></table>"


def bar_chart(rows: list[sqlite3.Row], label_key: str, value_key: str, title: str, unit: str = "") -> str:
    width = 860
    row_h = 34
    left = 150
    top = 42
    max_bar_w = width - left - 110
    height = top + row_h * len(rows) + 24
    values = [float(r[value_key] or 0) for r in rows]
    max_value = max(values) if values else 1
    parts = [
        f'<svg class="chart" viewBox="0 0 {width} {height}" role="img" aria-label="{esc(title)}">',
        f'<text x="0" y="22" class="chart-title">{esc(title)}</text>',
    ]
    for i, row in enumerate(rows):
        y = top + i * row_h
        value = float(row[value_key] or 0)
        bar_w = 0 if max_value == 0 else max_bar_w * value / max_value
        parts.append(f'<text x="0" y="{y + 17}" class="axis-label">{esc(row[label_key])}</text>')
        parts.append(f'<rect x="{left}" y="{y}" width="{bar_w:.1f}" height="20" rx="4" class="bar"></rect>')
        parts.append(f'<text x="{left + bar_w + 8:.1f}" y="{y + 16}" class="value-label">{num(value, unit)}</text>')
    parts.append("</svg>")
    return "".join(parts)


def line_chart(rows: list[sqlite3.Row], x_key: str, y_key: str, title: str) -> str:
    width, height = 860, 280
    pad_l, pad_r, pad_t, pad_b = 54, 20, 44, 46
    values = [float(r[y_key] or 0) for r in rows]
    if not rows or not values:
        return ""
    min_v, max_v = min(values), max(values)
    if min_v == max_v:
        min_v = 0
    points = []
    for i, row in enumerate(rows):
        x = pad_l + i * (width - pad_l - pad_r) / max(len(rows) - 1, 1)
        y = height - pad_b - (float(row[y_key]) - min_v) * (height - pad_t - pad_b) / (max_v - min_v)
        points.append((x, y, row[x_key], row[y_key]))
    path = " ".join(("M" if i == 0 else "L") + f"{x:.1f},{y:.1f}" for i, (x, y, _, _) in enumerate(points))
    x_labels = "".join(
        f'<text x="{x:.1f}" y="{height - 18}" class="tick" text-anchor="middle">{esc(label)}</text>'
        for x, _, label, _ in points[:: max(1, len(points) // 6)]
    )
    dots = "".join(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="3.5" class="dot"></circle>' for x, y, _, _ in points)
    return f"""
    <svg class="chart" viewBox="0 0 {width} {height}" role="img" aria-label="{esc(title)}">
      <text x="0" y="22" class="chart-title">{esc(title)}</text>
      <line x1="{pad_l}" y1="{height-pad_b}" x2="{width-pad_r}" y2="{height-pad_b}" class="grid"></line>
      <line x1="{pad_l}" y1="{pad_t}" x2="{pad_l}" y2="{height-pad_b}" class="grid"></line>
      <text x="4" y="{pad_t+8}" class="tick">{num(max_v)}</text>
      <text x="4" y="{height-pad_b}" class="tick">{num(min_v)}</text>
      <path d="{path}" class="line"></path>
      {dots}
      {x_labels}
    </svg>
    """


def main() -> None:
    if not DB_PATH.exists():
        raise SystemExit("Clean database not found. Run scripts/build_clean_db.py first.")

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        kpi = query(conn, "SELECT * FROM v_executive_kpi")[0]
        quality = query(conn, "SELECT * FROM v_data_quality_summary")
        priority = query(conn, """
            SELECT city, tier, readiness_score_2024, pilot_engagement_pct,
                   print_net_change_2019_2024_pct, print_efficiency_2024_pct,
                   dx_priority_score
            FROM v_city_dx_priority
            ORDER BY dx_priority_score DESC
        """)
        print_year = query(conn, """
            SELECT year, SUM(net_circulation) AS net_circulation
            FROM clean_fact_print_sales
            GROUP BY year
            ORDER BY year
        """)
        top_drop = query(conn, """
            SELECT city, month_start, mom_net_change, mom_net_change_pct
            FROM v_print_monthly_momentum
            WHERE mom_net_change IS NOT NULL
            ORDER BY mom_net_change ASC
            LIMIT 8
        """)
        ad_concentration = query(conn, """
            SELECT year, standard_ad_category, revenue_share_pct
            FROM v_ad_category_concentration
            WHERE revenue_share_pct = (
                SELECT MAX(v2.revenue_share_pct)
                FROM v_ad_category_concentration v2
                WHERE v2.year = v_ad_category_concentration.year
            )
            ORDER BY year
        """)
        top_revenue_2024 = query(conn, """
            SELECT city, ROUND(SUM(ad_revenue_inr), 0) AS ad_revenue_2024_inr
            FROM v_ad_revenue_yearly
            WHERE year = 2024
            GROUP BY city
            ORDER BY ad_revenue_2024_inr DESC
            LIMIT 8
        """)

        best_priority = priority[0]
        worst_drop = top_drop[0]

        html_doc = f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bharat Herald DX改善分析レポート</title>
  <style>
    :root {{
      --ink: #172033;
      --muted: #637083;
      --line: #d9dee8;
      --bg: #f6f7f9;
      --panel: #ffffff;
      --accent: #0f766e;
      --accent-2: #c2410c;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: "Yu Gothic", "Meiryo", "Noto Sans JP", Arial, sans-serif;
      color: var(--ink);
      background: var(--bg);
      line-height: 1.65;
    }}
    header {{
      background: #102033;
      color: white;
      padding: 42px 56px 36px;
    }}
    header p {{ max-width: 920px; color: #d6dee9; margin: 10px 0 0; }}
    main {{ max-width: 1120px; margin: 0 auto; padding: 28px 24px 56px; }}
    section {{ margin: 28px 0; }}
    h1 {{ font-size: 30px; margin: 0; letter-spacing: 0; }}
    h2 {{ font-size: 21px; margin: 0 0 14px; }}
    h3 {{ font-size: 16px; margin: 18px 0 8px; }}
    .kpis {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }}
    .kpi, .panel {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 18px;
    }}
    .kpi .label {{ color: var(--muted); font-size: 13px; }}
    .kpi .value {{ font-size: 23px; font-weight: 700; margin-top: 6px; }}
    .insights {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }}
    ul {{ padding-left: 20px; margin: 8px 0 0; }}
    li {{ margin: 6px 0; }}
    table {{ width: 100%; border-collapse: collapse; background: white; border: 1px solid var(--line); }}
    th, td {{ padding: 9px 10px; border-bottom: 1px solid var(--line); text-align: left; font-size: 13px; }}
    th {{ background: #edf2f7; font-weight: 700; }}
    .chart {{ width: 100%; max-width: 920px; display: block; margin: 10px 0 18px; }}
    .chart-title {{ font-size: 17px; font-weight: 700; fill: var(--ink); }}
    .axis-label, .value-label, .tick {{ font-size: 12px; fill: var(--muted); }}
    .bar {{ fill: var(--accent); }}
    .line {{ fill: none; stroke: var(--accent-2); stroke-width: 3; }}
    .dot {{ fill: var(--accent-2); }}
    .grid {{ stroke: var(--line); stroke-width: 1; }}
    .note {{ color: var(--muted); font-size: 13px; }}
    footer {{ color: var(--muted); font-size: 12px; margin-top: 28px; }}
    @media (max-width: 760px) {{
      header {{ padding: 30px 22px; }}
      .kpis, .insights {{ grid-template-columns: 1fr; }}
      main {{ padding: 20px 14px 42px; }}
      table {{ display: block; overflow-x: auto; }}
    }}
  </style>
</head>
<body>
  <header>
    <h1>Bharat Herald DX改善分析レポート</h1>
    <p>SQLでデータ品質・表記ゆれ・通貨・日付を再整備し、印刷事業の縮小リスクとデジタル移行の優先都市を再評価した。</p>
  </header>
  <main>
    <section class="kpis">
      <div class="kpi"><div class="label">2024年ネット部数</div><div class="value">{num(kpi['net_circulation_2024'])}</div></div>
      <div class="kpi"><div class="label">2024年平均印刷効率</div><div class="value">{num(kpi['avg_print_efficiency_2024_pct'], '%')}</div></div>
      <div class="kpi"><div class="label">2024年広告収入</div><div class="value">{yen(kpi['ad_revenue_2024_inr'])}</div></div>
      <div class="kpi"><div class="label">2024年DX準備度</div><div class="value">{num(kpi['avg_readiness_2024'])}</div></div>
      <div class="kpi"><div class="label">Pilot平均エンゲージメント</div><div class="value">{num(kpi['avg_pilot_engagement_pct'], '%')}</div></div>
      <div class="kpi"><div class="label">平均アクセス単価</div><div class="value">{yen(kpi['avg_cost_per_access_inr'])}</div></div>
    </section>

    <section class="insights">
      <div class="panel">
        <h2>結論</h2>
        <ul>
          <li>DX優先度が最も高い都市は <strong>{esc(best_priority['city'])}</strong>。準備度は高い一方、Pilot反応との差が大きい。</li>
          <li>最大の月次部数落ち込みは <strong>{esc(worst_drop['city'])}</strong> の {esc(worst_drop['month_start'])}、変化量は {num(worst_drop['mom_net_change'])} 部。</li>
          <li>広告収入はカテゴリ集中を持つ年があり、紙面依存の回復だけではDX投資原資が不安定になる。</li>
        </ul>
      </div>
      <div class="panel">
        <h2>改善後の分析観点</h2>
        <ul>
          <li>通貨をINRへ統一し、広告収入を横比較可能にした。</li>
          <li>印刷効率、返品率、月次変化率、Pilotアクセス単価を追加した。</li>
          <li>DX準備度、Pilot低反応、印刷縮小、効率低下を統合し、優先度スコアを作成した。</li>
        </ul>
      </div>
    </section>

    <section class="panel">
      <h2>データ品質チェック</h2>
      {table(quality, [('table_name', '対象テーブル'), ('row_count', '行数'), ('issue_count', '異常フラグ数')])}
      <p class="note">異常フラグは負値、範囲外、論理不整合、未知通貨などを検出する。</p>
    </section>

    <section class="panel">
      <h2>印刷事業トレンド</h2>
      {line_chart(print_year, 'year', 'net_circulation', 'ネット部数の年次推移')}
      <h3>月次落ち込み上位</h3>
      {table(top_drop, [('city', '都市'), ('month_start', '月'), ('mom_net_change', '前月差'), ('mom_net_change_pct', '前月比%')])}
    </section>

    <section class="panel">
      <h2>広告収入と集中リスク</h2>
      {bar_chart(top_revenue_2024, 'city', 'ad_revenue_2024_inr', '2024年 都市別広告収入', ' INR')}
      <h3>年別トップ広告カテゴリ</h3>
      {table(ad_concentration, [('year', '年'), ('standard_ad_category', '最大カテゴリ'), ('revenue_share_pct', '構成比%')])}
    </section>

    <section class="panel">
      <h2>DX優先都市ランキング</h2>
      {bar_chart(priority, 'city', 'dx_priority_score', 'DX優先度スコア', '')}
      {table(priority, [('city', '都市'), ('tier', 'Tier'), ('readiness_score_2024', '準備度'), ('pilot_engagement_pct', 'Pilot反応%'), ('print_net_change_2019_2024_pct', '部数変化%'), ('print_efficiency_2024_pct', '印刷効率%'), ('dx_priority_score', 'DX優先度')])}
    </section>

    <section class="panel">
      <h2>提案</h2>
      <ul>
        <li>高準備度・低Pilot反応の都市では、単純なアプリ展開よりWhatsApp/地域広告主連携から再設計する。</li>
        <li>印刷効率が低い都市は、部数予測と返品率モニタリングを月次KPI化し、紙面コストをDX投資へ振り替える。</li>
        <li>広告カテゴリ集中が高い年は、Government/FMCG/Real Estateの偏りを見ながらデジタル広告商品を分散投入する。</li>
      </ul>
    </section>

    <footer>
      Generated by scripts/generate_japanese_report.py on {datetime.now().strftime('%Y-%m-%d %H:%M')}.
    </footer>
  </main>
</body>
</html>"""

        REPORT_PATH.write_text(html_doc, encoding="utf-8")
        print(f"Japanese report created: {REPORT_PATH}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
