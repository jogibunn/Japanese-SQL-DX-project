-- ================================================================
-- Bharat Herald DX分析: 深層データクリーニングSQL
-- 目的:
--   1. CSV由来の表記ゆれを分析用の正規化テーブルへ変換する
--   2. 日付・通貨・都市名・広告カテゴリを統一する
--   3. 異常値フラグとDX判断に必要な派生指標を作成する
-- 実行:
--   scripts/build_clean_db.py が raw_* テーブルを作成した後に本SQLを実行する
-- DB:
--   SQLite 3
-- ================================================================

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS clean_dim_city;
CREATE TABLE clean_dim_city AS
SELECT
    UPPER(TRIM(city_id)) AS city_id,
    CASE UPPER(TRIM(city_id))
        WHEN 'C001' THEN 'Lucknow'
        WHEN 'C002' THEN 'Delhi'
        WHEN 'C003' THEN 'Bhopal'
        WHEN 'C004' THEN 'Patna'
        WHEN 'C005' THEN 'Jaipur'
        WHEN 'C006' THEN 'Mumbai'
        WHEN 'C007' THEN 'Ranchi'
        WHEN 'C008' THEN 'Kanpur'
        WHEN 'C009' THEN 'Ahmedabad'
        WHEN 'C010' THEN 'Varanasi'
        ELSE TRIM(city)
    END AS city,
    CASE UPPER(REPLACE(TRIM(state), '_', ' '))
        WHEN 'UTTAR PRADESH' THEN 'Uttar Pradesh'
        WHEN 'DELHI' THEN 'Delhi'
        WHEN 'MADHYA PRADESH' THEN 'Madhya Pradesh'
        WHEN 'BIHAR' THEN 'Bihar'
        WHEN 'RAJASTHAN' THEN 'Rajasthan'
        WHEN 'MAHARASHTRA' THEN 'Maharashtra'
        WHEN 'JHARKHAND' THEN 'Jharkhand'
        WHEN 'GUJARAT' THEN 'Gujarat'
        ELSE TRIM(state)
    END AS state,
    TRIM(tier) AS tier
FROM raw_dim_city;

DROP TABLE IF EXISTS clean_dim_ad_category;
CREATE TABLE clean_dim_ad_category AS
SELECT
    UPPER(TRIM(ad_category_id)) AS ad_category_id,
    TRIM(standard_ad_category) AS standard_ad_category,
    TRIM(category_group) AS category_group,
    TRIM(example_brands) AS example_brands
FROM raw_dim_ad_category;

DROP TABLE IF EXISTS clean_fact_print_sales;
CREATE TABLE clean_fact_print_sales AS
WITH normalized AS (
    SELECT
        UPPER(TRIM(edition_ID)) AS edition_id,
        UPPER(TRIM(City_ID)) AS city_id,
        'Hindi' AS language,
        TRIM(Month) AS month_raw,
        CAST(REPLACE(TRIM("Copies Sold"), ',', '') AS INTEGER) AS gross_copies_sold,
        CAST(REPLACE(TRIM(copies_returned), ',', '') AS INTEGER) AS copies_returned,
        CAST(REPLACE(TRIM(Net_Circulation), ',', '') AS INTEGER) AS net_circulation
    FROM raw_fact_print_sales
),
dated AS (
    SELECT
        *,
        CASE SUBSTR(month_raw, 1, 3)
            WHEN 'Jan' THEN 1 WHEN 'Feb' THEN 2 WHEN 'Mar' THEN 3
            WHEN 'Apr' THEN 4 WHEN 'May' THEN 5 WHEN 'Jun' THEN 6
            WHEN 'Jul' THEN 7 WHEN 'Aug' THEN 8 WHEN 'Sep' THEN 9
            WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12
        END AS month_no,
        CAST('20' || SUBSTR(month_raw, 5, 2) AS INTEGER) AS year
    FROM normalized
)
SELECT
    edition_id,
    city_id,
    language,
    printf('%04d-%02d-01', year, month_no) AS month_start,
    year,
    month_no,
    gross_copies_sold,
    copies_returned,
    net_circulation,
    ROUND(100.0 * copies_returned / NULLIF(gross_copies_sold, 0), 2) AS return_rate_pct,
    ROUND(100.0 * net_circulation / NULLIF(gross_copies_sold, 0), 2) AS circulation_efficiency_pct,
    CASE
        WHEN gross_copies_sold < 0 OR copies_returned < 0 OR net_circulation < 0 THEN 1
        WHEN copies_returned > gross_copies_sold THEN 1
        WHEN net_circulation <> gross_copies_sold - copies_returned THEN 1
        ELSE 0
    END AS print_logic_issue_flag
FROM dated;

DROP TABLE IF EXISTS clean_fact_ad_revenue;
CREATE TABLE clean_fact_ad_revenue AS
WITH normalized AS (
    SELECT
        UPPER(TRIM(edition_id)) AS edition_id,
        'C' || SUBSTR(UPPER(TRIM(edition_id)), 4, 3) AS city_id,
        UPPER(TRIM(ad_category)) AS ad_category_id,
        TRIM(quarter) AS quarter_raw,
        CAST(REPLACE(TRIM(ad_revenue), ',', '') AS REAL) AS ad_revenue_original,
        UPPER(TRIM(currency)) AS currency,
        TRIM(comments) AS comments
    FROM raw_fact_ad_revenue
),
dated AS (
    SELECT
        *,
        CASE
            WHEN quarter_raw GLOB '[0-9][0-9][0-9][0-9]-Q[1-4]' THEN CAST(SUBSTR(quarter_raw, 1, 4) AS INTEGER)
            WHEN quarter_raw GLOB 'Q[1-4]-[0-9][0-9][0-9][0-9]' THEN CAST(SUBSTR(quarter_raw, 4, 4) AS INTEGER)
            WHEN quarter_raw LIKE '%Qtr%' THEN CAST(SUBSTR(quarter_raw, LENGTH(quarter_raw) - 3, 4) AS INTEGER)
        END AS year,
        CASE
            WHEN quarter_raw GLOB '[0-9][0-9][0-9][0-9]-Q[1-4]' THEN CAST(SUBSTR(quarter_raw, 7, 1) AS INTEGER)
            WHEN quarter_raw GLOB 'Q[1-4]-[0-9][0-9][0-9][0-9]' THEN CAST(SUBSTR(quarter_raw, 2, 1) AS INTEGER)
            WHEN quarter_raw LIKE '%Qtr%' THEN CAST(SUBSTR(quarter_raw, 1, 1) AS INTEGER)
        END AS quarter_no
    FROM normalized
)
SELECT
    edition_id,
    city_id,
    ad_category_id,
    printf('%04d-Q%d', year, quarter_no) AS quarter,
    year,
    quarter_no,
    ad_revenue_original,
    currency,
    -- 分析用の簡易換算レート。元データは履歴為替を持たないため、比較可能性を優先して固定レートに統一する。
    CASE currency
        WHEN 'INR' THEN 1.0
        WHEN 'USD' THEN 83.0
        WHEN 'EUR' THEN 90.0
        ELSE NULL
    END AS fx_rate_to_inr,
    ROUND(ad_revenue_original * CASE currency
        WHEN 'INR' THEN 1.0
        WHEN 'USD' THEN 83.0
        WHEN 'EUR' THEN 90.0
        ELSE NULL
    END, 2) AS ad_revenue_inr,
    comments,
    CASE
        WHEN ad_revenue_original IS NULL OR ad_revenue_original < 0 THEN 1
        WHEN currency NOT IN ('INR', 'USD', 'EUR') THEN 1
        WHEN year NOT BETWEEN 2019 AND 2024 THEN 1
        ELSE 0
    END AS revenue_issue_flag
FROM dated;

DROP TABLE IF EXISTS clean_fact_city_readiness;
CREATE TABLE clean_fact_city_readiness AS
WITH normalized AS (
    SELECT
        UPPER(TRIM(city_id)) AS city_id,
        TRIM(quarter) AS quarter,
        CAST(TRIM(literacy_rate) AS REAL) AS literacy_rate,
        CAST(TRIM(smartphone_penetration) AS REAL) AS smartphone_penetration,
        CAST(TRIM(internet_penetration) AS REAL) AS internet_penetration
    FROM raw_fact_city_readiness
)
SELECT
    city_id,
    quarter,
    CAST(SUBSTR(quarter, 1, 4) AS INTEGER) AS year,
    CAST(SUBSTR(quarter, 7, 1) AS INTEGER) AS quarter_no,
    literacy_rate,
    smartphone_penetration,
    internet_penetration,
    ROUND((literacy_rate * 0.30) + (smartphone_penetration * 0.35) + (internet_penetration * 0.35), 2) AS readiness_score,
    CASE
        WHEN literacy_rate NOT BETWEEN 0 AND 100 THEN 1
        WHEN smartphone_penetration NOT BETWEEN 0 AND 100 THEN 1
        WHEN internet_penetration NOT BETWEEN 0 AND 100 THEN 1
        ELSE 0
    END AS readiness_issue_flag
FROM normalized;

DROP TABLE IF EXISTS clean_fact_digital_pilot;
CREATE TABLE clean_fact_digital_pilot AS
SELECT
    TRIM(platform) AS platform,
    DATE(TRIM(launch_month) || '-01') AS launch_month,
    CAST(SUBSTR(TRIM(launch_month), 1, 4) AS INTEGER) AS year,
    CAST(SUBSTR(TRIM(launch_month), 6, 2) AS INTEGER) AS month_no,
    UPPER(TRIM(city_id)) AS city_id,
    UPPER(TRIM(ad_category_id)) AS ad_category_id,
    CAST(TRIM(dev_cost) AS REAL) AS dev_cost,
    CAST(TRIM(marketing_cost) AS REAL) AS marketing_cost,
    CAST(TRIM(users_reached) AS INTEGER) AS users_reached,
    CAST(TRIM(downloads_or_accesses) AS INTEGER) AS downloads_or_accesses,
    CAST(TRIM(avg_bounce_rate) AS REAL) AS avg_bounce_rate,
    TRIM(cumulative_feedback_from_customers) AS feedback,
    ROUND(100.0 * CAST(TRIM(downloads_or_accesses) AS REAL) / NULLIF(CAST(TRIM(users_reached) AS REAL), 0), 2) AS engagement_rate_pct,
    ROUND((CAST(TRIM(dev_cost) AS REAL) + CAST(TRIM(marketing_cost) AS REAL)) / NULLIF(CAST(TRIM(downloads_or_accesses) AS REAL), 0), 2) AS cost_per_access_inr,
    CASE
        WHEN CAST(TRIM(downloads_or_accesses) AS INTEGER) > CAST(TRIM(users_reached) AS INTEGER) THEN 1
        WHEN CAST(TRIM(avg_bounce_rate) AS REAL) NOT BETWEEN 0 AND 100 THEN 1
        WHEN CAST(TRIM(dev_cost) AS REAL) < 0 OR CAST(TRIM(marketing_cost) AS REAL) < 0 THEN 1
        ELSE 0
    END AS pilot_issue_flag
FROM raw_fact_digital_pilot;

DROP VIEW IF EXISTS v_data_quality_summary;
CREATE VIEW v_data_quality_summary AS
SELECT 'print_sales' AS table_name, COUNT(*) AS row_count, SUM(print_logic_issue_flag) AS issue_count FROM clean_fact_print_sales
UNION ALL
SELECT 'ad_revenue', COUNT(*), SUM(revenue_issue_flag) FROM clean_fact_ad_revenue
UNION ALL
SELECT 'city_readiness', COUNT(*), SUM(readiness_issue_flag) FROM clean_fact_city_readiness
UNION ALL
SELECT 'digital_pilot', COUNT(*), SUM(pilot_issue_flag) FROM clean_fact_digital_pilot;

DROP VIEW IF EXISTS v_print_monthly_momentum;
CREATE VIEW v_print_monthly_momentum AS
SELECT
    c.city,
    c.tier,
    p.city_id,
    p.month_start,
    p.year,
    p.month_no,
    p.gross_copies_sold,
    p.copies_returned,
    p.net_circulation,
    p.return_rate_pct,
    p.circulation_efficiency_pct,
    p.net_circulation - LAG(p.net_circulation) OVER (PARTITION BY p.city_id ORDER BY p.month_start) AS mom_net_change,
    ROUND(100.0 * (p.net_circulation - LAG(p.net_circulation) OVER (PARTITION BY p.city_id ORDER BY p.month_start))
        / NULLIF(LAG(p.net_circulation) OVER (PARTITION BY p.city_id ORDER BY p.month_start), 0), 2) AS mom_net_change_pct
FROM clean_fact_print_sales p
LEFT JOIN clean_dim_city c ON p.city_id = c.city_id;

DROP VIEW IF EXISTS v_print_city_yearly;
CREATE VIEW v_print_city_yearly AS
SELECT
    c.city,
    c.tier,
    p.city_id,
    p.year,
    SUM(p.gross_copies_sold) AS gross_copies_sold,
    SUM(p.copies_returned) AS copies_returned,
    SUM(p.net_circulation) AS net_circulation,
    ROUND(100.0 * SUM(p.net_circulation) / NULLIF(SUM(p.gross_copies_sold), 0), 2) AS circulation_efficiency_pct,
    ROUND(100.0 * SUM(p.copies_returned) / NULLIF(SUM(p.gross_copies_sold), 0), 2) AS return_rate_pct
FROM clean_fact_print_sales p
LEFT JOIN clean_dim_city c ON p.city_id = c.city_id
GROUP BY c.city, c.tier, p.city_id, p.year;

DROP VIEW IF EXISTS v_ad_revenue_yearly;
CREATE VIEW v_ad_revenue_yearly AS
SELECT
    c.city,
    c.tier,
    a.city_id,
    d.standard_ad_category,
    d.category_group,
    a.year,
    ROUND(SUM(a.ad_revenue_inr), 2) AS ad_revenue_inr
FROM clean_fact_ad_revenue a
LEFT JOIN clean_dim_city c ON a.city_id = c.city_id
LEFT JOIN clean_dim_ad_category d ON a.ad_category_id = d.ad_category_id
GROUP BY c.city, c.tier, a.city_id, d.standard_ad_category, d.category_group, a.year;

DROP VIEW IF EXISTS v_ad_category_concentration;
CREATE VIEW v_ad_category_concentration AS
WITH category_sum AS (
    SELECT
        year,
        standard_ad_category,
        SUM(ad_revenue_inr) AS category_revenue
    FROM v_ad_revenue_yearly
    GROUP BY year, standard_ad_category
),
year_sum AS (
    SELECT year, SUM(category_revenue) AS total_revenue
    FROM category_sum
    GROUP BY year
)
SELECT
    c.year,
    c.standard_ad_category,
    ROUND(c.category_revenue, 2) AS category_revenue_inr,
    ROUND(100.0 * c.category_revenue / NULLIF(y.total_revenue, 0), 2) AS revenue_share_pct
FROM category_sum c
JOIN year_sum y ON c.year = y.year;

DROP VIEW IF EXISTS v_city_dx_priority;
CREATE VIEW v_city_dx_priority AS
WITH print_2024 AS (
    SELECT
        city_id,
        SUM(net_circulation) AS net_2024,
        AVG(circulation_efficiency_pct) AS efficiency_2024
    FROM clean_fact_print_sales
    WHERE year = 2024
    GROUP BY city_id
),
print_2019 AS (
    SELECT city_id, SUM(net_circulation) AS net_2019
    FROM clean_fact_print_sales
    WHERE year = 2019
    GROUP BY city_id
),
readiness_2024 AS (
    SELECT city_id, AVG(readiness_score) AS readiness_score_2024
    FROM clean_fact_city_readiness
    WHERE year = 2024
    GROUP BY city_id
),
pilot_2021 AS (
    SELECT
        city_id,
        AVG(engagement_rate_pct) AS pilot_engagement_pct,
        AVG(avg_bounce_rate) AS avg_bounce_rate,
        AVG(cost_per_access_inr) AS cost_per_access_inr
    FROM clean_fact_digital_pilot
    GROUP BY city_id
),
ad_2024 AS (
    SELECT city_id, SUM(ad_revenue_inr) AS ad_revenue_2024
    FROM clean_fact_ad_revenue
    WHERE year = 2024
    GROUP BY city_id
)
SELECT
    c.city,
    c.tier,
    c.city_id,
    ROUND(r.readiness_score_2024, 2) AS readiness_score_2024,
    ROUND(p.pilot_engagement_pct, 2) AS pilot_engagement_pct,
    ROUND(p.avg_bounce_rate, 2) AS avg_bounce_rate,
    ROUND(p.cost_per_access_inr, 2) AS cost_per_access_inr,
    ROUND(100.0 * (p24.net_2024 - p19.net_2019) / NULLIF(p19.net_2019, 0), 2) AS print_net_change_2019_2024_pct,
    ROUND(p24.efficiency_2024, 2) AS print_efficiency_2024_pct,
    ROUND(a.ad_revenue_2024, 2) AS ad_revenue_2024_inr,
    ROUND(
        COALESCE(r.readiness_score_2024, 0) * 0.40
        + (100.0 - COALESCE(p.pilot_engagement_pct, 0)) * 0.25
        + ABS(MIN(COALESCE(100.0 * (p24.net_2024 - p19.net_2019) / NULLIF(p19.net_2019, 0), 0), 0)) * 0.20
        + (100.0 - COALESCE(p24.efficiency_2024, 0)) * 0.15
    , 2) AS dx_priority_score
FROM clean_dim_city c
LEFT JOIN readiness_2024 r ON c.city_id = r.city_id
LEFT JOIN pilot_2021 p ON c.city_id = p.city_id
LEFT JOIN print_2024 p24 ON c.city_id = p24.city_id
LEFT JOIN print_2019 p19 ON c.city_id = p19.city_id
LEFT JOIN ad_2024 a ON c.city_id = a.city_id;

DROP VIEW IF EXISTS v_executive_kpi;
CREATE VIEW v_executive_kpi AS
SELECT
    (SELECT SUM(net_circulation) FROM clean_fact_print_sales WHERE year = 2024) AS net_circulation_2024,
    (SELECT ROUND(AVG(circulation_efficiency_pct), 2) FROM clean_fact_print_sales WHERE year = 2024) AS avg_print_efficiency_2024_pct,
    (SELECT ROUND(SUM(ad_revenue_inr), 2) FROM clean_fact_ad_revenue WHERE year = 2024) AS ad_revenue_2024_inr,
    (SELECT ROUND(AVG(readiness_score), 2) FROM clean_fact_city_readiness WHERE year = 2024) AS avg_readiness_2024,
    (SELECT ROUND(AVG(engagement_rate_pct), 2) FROM clean_fact_digital_pilot) AS avg_pilot_engagement_pct,
    (SELECT ROUND(AVG(cost_per_access_inr), 2) FROM clean_fact_digital_pilot) AS avg_cost_per_access_inr;

CREATE INDEX IF NOT EXISTS idx_clean_print_city_month ON clean_fact_print_sales(city_id, month_start);
CREATE INDEX IF NOT EXISTS idx_clean_ad_city_year ON clean_fact_ad_revenue(city_id, year);
CREATE INDEX IF NOT EXISTS idx_clean_readiness_city_year ON clean_fact_city_readiness(city_id, year);
CREATE INDEX IF NOT EXISTS idx_clean_pilot_city ON clean_fact_digital_pilot(city_id);

PRAGMA foreign_keys = ON;
