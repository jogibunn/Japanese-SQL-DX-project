"""CSVをSQLiteへ取り込み、日語コメント付きSQLでクレンジングDBを作成する。"""

from __future__ import annotations

import csv
import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "New Datasets"
SQL_FILE = ROOT / "improved_sql_jp" / "01_deep_data_cleaning.sql"
OUTPUT_DB = ROOT / "improved_outputs" / "bharat_herald_cleaned.sqlite"

CSV_TABLES = {
    "dim_city_utf8.csv": "raw_dim_city",
    "dim_ad_category_utf8.csv": "raw_dim_ad_category",
    "fact_print_sales_utf8.csv": "raw_fact_print_sales",
    "fact_ad_revenue.csv": "raw_fact_ad_revenue",
    "fact_city_readiness.csv": "raw_fact_city_readiness",
    "fact_digital_pilot.csv": "raw_fact_digital_pilot",
}


def quote_identifier(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def normalize_header(header: str, index: int) -> str:
    """空列名だけ補正し、それ以外はSQL側で元名を参照できるよう維持する。"""
    cleaned = header.strip()
    if cleaned:
        return cleaned
    return f"source_row_id_{index}"


def load_csv(conn: sqlite3.Connection, csv_name: str, table_name: str) -> int:
    path = DATA_DIR / csv_name
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f)
        headers = [normalize_header(h, i) for i, h in enumerate(next(reader))]
        rows = list(reader)

    conn.execute(f"DROP TABLE IF EXISTS {quote_identifier(table_name)}")
    columns_sql = ", ".join(f"{quote_identifier(h)} TEXT" for h in headers)
    conn.execute(f"CREATE TABLE {quote_identifier(table_name)} ({columns_sql})")

    placeholders = ", ".join("?" for _ in headers)
    insert_sql = f"INSERT INTO {quote_identifier(table_name)} VALUES ({placeholders})"
    conn.executemany(insert_sql, rows)
    return len(rows)


def main() -> None:
    OUTPUT_DB.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT_DB.exists():
        OUTPUT_DB.unlink()

    conn = sqlite3.connect(OUTPUT_DB)
    try:
        loaded_counts = {}
        for csv_name, table_name in CSV_TABLES.items():
            loaded_counts[table_name] = load_csv(conn, csv_name, table_name)

        sql = SQL_FILE.read_text(encoding="utf-8")
        conn.executescript(sql)
        conn.commit()

        print("Clean database created:")
        print(f"  {OUTPUT_DB}")
        print("Loaded raw rows:")
        for table_name, count in loaded_counts.items():
            print(f"  {table_name}: {count}")

        print("Quality summary:")
        for row in conn.execute("SELECT table_name, row_count, issue_count FROM v_data_quality_summary"):
            print(f"  {row[0]}: rows={row[1]}, issues={row[2]}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
