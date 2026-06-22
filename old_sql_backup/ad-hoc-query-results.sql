-- =========================================================
-- Bharat Herald Business Requests (Q1 – Q6)
-- Period: 2019–2024
-- =========================================================

-- ================================
-- Q1: Monthly Circulation Drop Check
-- Top 3 months where any city recorded sharpest MoM drop
-- ================================
WITH sales_month AS (
    SELECT
        fps.city_id,
        d.city AS city_name,
        month,
        month_date,
        SUM(fps.net_circulation) AS net_circulation
    FROM fact_print_sales fps
    JOIN dim_city d ON fps.city_id = d.city_id
    GROUP BY fps.city_id, d.city, month, month_date
),
sales_change AS (
    SELECT
        sm.*,
        LAG(sm.net_circulation) OVER (PARTITION BY sm.city_id ORDER BY sm.month_date) AS prev_net,
        (LAG(sm.net_circulation) OVER (PARTITION BY sm.city_id ORDER BY sm.month_date) - sm.net_circulation) AS drop_amount
    FROM sales_month sm
)
SELECT
    sc.city_name,
    sc.month,
    sc.net_circulation,
    sc.drop_amount
FROM sales_change sc
WHERE sc.prev_net IS NOT NULL
  AND sc.drop_amount > 0
  AND sc.month_date BETWEEN '2019-01-01' AND '2024-12-31'
ORDER BY sc.drop_amount DESC
LIMIT 5;    

-- ================================
-- Q2: Yearly Revenue Concentration by Category
-- Ad categories >50% of yearly revenue
-- ================================
WITH yearly_rev AS (
    SELECT
        LEFT(far.quarter,4) AS year,
        dac.standard_ad_category AS category_name,
        SUM(far.ad_revenue) AS category_revenue
    FROM fact_ad_revenue far
    JOIN dim_ad_category dac ON far.ad_category = dac.ad_category_id
    GROUP BY LEFT(far.quarter,4), dac.standard_ad_category
),
year_totals AS (
    SELECT year, SUM(category_revenue) AS total_revenue_year
    FROM yearly_rev
    GROUP BY year
)
SELECT
    yr.year,
    yr.category_name,
    yr.category_revenue,
    yt.total_revenue_year,
    ROUND((yr.category_revenue / yt.total_revenue_year) * 100,2) AS pct_of_year_total
FROM yearly_rev yr
JOIN year_totals yt ON yr.year = yt.year
WHERE (yr.category_revenue / yt.total_revenue_year) > 0.5
ORDER BY yr.year, pct_of_year_total DESC;

-- ================================
-- Q3: 2024 Print Efficiency Leaderboard
-- Top 5 cities by efficiency ratio
-- ================================
WITH yearly_2024 AS (
    SELECT
        fps.city_id,
        d.city AS city_name,
        SUM(fps.net_circulation) AS net_circulation_2024,
        SUM(fps.copies_sold + fps.copies_returned) AS copies_printed_2024
    FROM fact_print_sales fps
    JOIN dim_city d ON fps.city_id = d.city_id
    WHERE YEAR(fps.month_date) = 2024
    GROUP BY fps.city_id, d.city
)
SELECT
    city_name,
    copies_printed_2024,
    net_circulation_2024,
    ROUND(net_circulation_2024 / NULLIF(copies_printed_2024,0),3) AS efficiency_ratio,
    RANK() OVER (ORDER BY net_circulation_2024 / NULLIF(copies_printed_2024,0) DESC) AS efficiency_rank_2024
FROM yearly_2024
ORDER BY efficiency_rank_2024
LIMIT 5;

-- ================================
-- Q4: Internet Readiness Growth (2021)
-- Highest improvement from Q1→Q4 2021
-- ================================
WITH q1 AS (
    SELECT d.city, fcr.internet_penetration AS internet_rate_q1
    FROM fact_city_readiness fcr
    JOIN dim_city d ON fcr.city_id = d.city_id
    WHERE fcr.quarter = '2021-Q1'
),
q4 AS (
    SELECT d.city, fcr.internet_penetration AS internet_rate_q4
    FROM fact_city_readiness fcr
    JOIN dim_city d ON fcr.city_id = d.city_id
    WHERE fcr.quarter = '2021-Q4'
)
SELECT 
    q1.city,
    q1.internet_rate_q1,
    q4.internet_rate_q4,
    (q4.internet_rate_q4 - q1.internet_rate_q1) AS delta_internet_rate
FROM q1
JOIN q4 ON q1.city = q4.city
ORDER BY delta_internet_rate DESC
LIMIT 1;

-- ================================
-- Q5: Consistent Multi-Year Decline (2019–2024)
-- Cities where both print circulation & ad revenue declined
-- ================================
-- Step 1: Yearly Print
WITH yearly_print AS (
    SELECT
        fps.city_id,
        d.city,
        YEAR(fps.month_date) AS year,
        SUM(fps.net_circulation) AS yearly_net_circulation
    FROM fact_print_sales fps
    JOIN dim_city d ON fps.city_id = d.city_id
    WHERE YEAR(fps.month_date) BETWEEN 2019 AND 2024
    GROUP BY fps.city_id, d.city, YEAR(fps.month_date)
),
print_check AS (
    SELECT
        yp.city,
        MIN(yp.yearly_net_circulation) <> MAX(yp.yearly_net_circulation) AS has_variation,
        SUM(CASE WHEN yp.yearly_net_circulation > 
                     LAG(yp.yearly_net_circulation) OVER (PARTITION BY yp.city ORDER BY yp.year)
                 THEN 1 ELSE 0 END) AS increase_count
    FROM yearly_print yp
    GROUP BY yp.city
),
-- Step 2: Yearly Ad Revenue
yearly_ad AS (
    SELECT
        far.edition_id,
        LEFT(far.quarter,4) AS year,
        SUM(far.ad_revenue) AS yearly_ad_revenue
    FROM fact_ad_revenue far
    WHERE LEFT(far.quarter,4) BETWEEN '2019' AND '2024'
    GROUP BY far.edition_id, LEFT(far.quarter,4)
),
ad_check AS (
    SELECT
        ya.edition_id,
        MIN(ya.yearly_ad_revenue) <> MAX(ya.yearly_ad_revenue) AS has_variation,
        SUM(CASE WHEN ya.yearly_ad_revenue > 
                     LAG(ya.yearly_ad_revenue) OVER (PARTITION BY ya.edition_id ORDER BY ya.year)
                 THEN 1 ELSE 0 END) AS increase_count
    FROM yearly_ad ya
    GROUP BY ya.edition_id
)
-- Step 3: Final Join
SELECT 
    d.city,
    CASE WHEN pc.increase_count = 0 AND pc.has_variation = 1 THEN 'Yes' ELSE 'No' END AS is_declining_print,
    CASE WHEN ac.increase_count = 0 AND ac.has_variation = 1 THEN 'Yes' ELSE 'No' END AS is_declining_ad_revenue,
    CASE 
        WHEN (pc.increase_count = 0 AND pc.has_variation = 1) 
         AND (ac.increase_count = 0 AND ac.has_variation = 1) 
        THEN 'Yes' ELSE 'No'
    END AS is_declining_both
FROM dim_city d
LEFT JOIN print_check pc ON d.city = pc.city
LEFT JOIN ad_check ac ON d.city = ac.edition_id;

-- ================================
-- Q6: 2021 Readiness vs Pilot Engagement Outlier
-- Highest readiness but bottom 3 engagement
-- ================================
WITH readiness AS (
    SELECT 
        d.city,
        AVG((fcr.literacy_rate + fcr.smartphone_penetration + fcr.internet_penetration) / 3) AS readiness_score_2021
    FROM fact_city_readiness fcr
    JOIN dim_city d ON fcr.city_id = d.city_id
    WHERE fcr.quarter LIKE '2021-Q%'
    GROUP BY d.city
),
engagement AS (
    SELECT 
        d.city,
        SUM(fdp.downloads_or_accesses) AS engagement_metric_2021
    FROM fact_digital_pilot fdp
    JOIN dim_city d ON fdp.city_id = d.city_id
    WHERE fdp.launch_month LIKE '2021-%'
    GROUP BY d.city
),
ranked AS (
    SELECT 
        r.city,
        r.readiness_score_2021,
        e.engagement_metric_2021,
        RANK() OVER (ORDER BY r.readiness_score_2021 DESC) AS readiness_rank_desc,
        RANK() OVER (ORDER BY e.engagement_metric_2021 ASC) AS engagement_rank_asc
    FROM readiness r
    JOIN engagement e ON r.city = e.city
)
SELECT 
    city,
    readiness_score_2021,
    engagement_metric_2021,
    readiness_rank_desc,
    engagement_rank_asc,
    CASE WHEN readiness_rank_desc = 1 AND engagement_rank_asc <= 3 
         THEN 'Yes' ELSE 'No' END AS is_outlier
FROM ranked;
