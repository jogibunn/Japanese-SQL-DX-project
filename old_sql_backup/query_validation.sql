-- ============================================================
-- Validation Queries for Bharat Herald Data Warehouse
-- Run after cleaning_queries.sql
-- Purpose: Quickly validate data quality & business sanity
-- ============================================================

-- 1. Row counts for all tables
SELECT 'dim_city' AS table_name, COUNT(*) AS row_count FROM dim_city
UNION ALL
SELECT 'dim_ad_category', COUNT(*) FROM dim_ad_category
UNION ALL
SELECT 'fact_ad_revenue', COUNT(*) FROM fact_ad_revenue
UNION ALL
SELECT 'fact_city_readiness', COUNT(*) FROM fact_city_readiness
UNION ALL
SELECT 'fact_digital_pilot', COUNT(*) FROM fact_digital_pilot
UNION ALL
SELECT 'fact_print_sales', COUNT(*) FROM fact_print_sales;

-- 2. Unique city count
SELECT COUNT(DISTINCT city_id) AS unique_cities FROM dim_city;

-- 3. Unique ad categories
SELECT COUNT(DISTINCT standard_ad_category) AS unique_categories FROM dim_ad_category;

-- 4. Unique editions in ad revenue
SELECT COUNT(DISTINCT edition_id) AS unique_editions FROM fact_ad_revenue;

-- 5. Unique cities in print sales
SELECT COUNT(DISTINCT city_id) AS unique_cities_in_sales FROM fact_print_sales;

-- 6. Foreign key consistency: ad categories in fact_ad_revenue must exist in dim_ad_category
SELECT DISTINCT fa.ad_category
FROM fact_ad_revenue fa
LEFT JOIN dim_ad_category dc ON fa.ad_category = dc.standard_ad_category
WHERE dc.standard_ad_category IS NULL;

-- 7. Foreign key consistency: cities in fact_digital_pilot must exist in dim_city
SELECT DISTINCT fp.city_id
FROM fact_digital_pilot fp
LEFT JOIN dim_city c ON fp.city_id = c.city_id
WHERE c.city_id IS NULL;

-- 8. Foreign key consistency: cities in fact_print_sales must exist in dim_city
SELECT DISTINCT fps.city_id
FROM fact_print_sales fps
LEFT JOIN dim_city c ON fps.city_id = c.city_id
WHERE c.city_id IS NULL;

-- 9. Revenue sanity check (min, max, avg)
SELECT MIN(ad_revenue) AS min_rev, MAX(ad_revenue) AS max_rev, AVG(ad_revenue) AS avg_rev
FROM fact_ad_revenue;

-- 10. Bounce rate sanity check (0–100%)
SELECT MIN(avg_bounce_rate) AS min_bounce, MAX(avg_bounce_rate) AS max_bounce
FROM fact_digital_pilot;

-- 11. Net circulation consistency check
SELECT COUNT(*) AS bad_net_rows
FROM fact_print_sales
WHERE net_circulation <> (`Copies Sold` - copies_returned);

-- 12. Zero copies_sold rows
SELECT COUNT(*) AS zero_sold_rows
FROM fact_print_sales
WHERE `Copies Sold` = 0;

-- 13. Distinct normalized quarters in ad revenue
SELECT DISTINCT quarter FROM fact_ad_revenue ORDER BY quarter;

-- 14. Distinct normalized months in print sales
SELECT DISTINCT month FROM fact_print_sales ORDER BY month;

-- 15. Spot check month_date index usage (example 2021 range)
EXPLAIN SELECT *
FROM fact_print_sales
WHERE month_date BETWEEN '2021-01-01' AND '2021-12-31';


--out put the new data after cleaning
UPDATE fact_print_sales
SET `Copies Sold` = REPLACE(`Copies Sold`, '???', '')
WHERE `Copies Sold` LIKE '%???%';

SELECT * FROM fact_print_sales WHERE `Copies Sold` LIKE '%???%';
SELECT * FROM fact_print_sales;

