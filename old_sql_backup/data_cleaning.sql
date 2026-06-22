-- ==============================================================
-- Bharat Herald Data Cleaning Script
-- Purpose: Standardize and clean fact/dimension tables
-- Author: [CHANG XIWEN]
-- Notes: Each section explains WHY cleaning was applied
-- ==============================================================

-- ==============================================================
-- 1. FACT_AD_REVENUE CLEANING
-- ==============================================================

-- Ad revenue was originally stored as VARCHAR and sometimes had
-- text like "IN RUPEES" mixed in. We first widen column type,
-- clean values, and then convert to DECIMAL for analysis.

ALTER TABLE fact_ad_revenue
    MODIFY ad_revenue VARCHAR(50),
    MODIFY quarter VARCHAR(50);

-- Normalize currency labels (e.g., "IN RUPEES", "RUPEES" → "INR")
UPDATE fact_ad_revenue
    SET currency = 'INR'
    WHERE currency IN ('IN RUPEES','RUPEES');

-- Remove text suffix from revenue amounts (e.g., "50000 IN RUPEES")
UPDATE fact_ad_revenue
    SET ad_revenue = REPLACE(ad_revenue,'IN RUPEES','')
    WHERE ad_revenue LIKE '%IN RUPEES%';

-- Convert revenue to numeric type for aggregations and comparisons
ALTER TABLE fact_ad_revenue
    MODIFY ad_revenue DECIMAL(15,2);

-- Quarters were inconsistent ("2019-Q2", "Q1-2020", "4th Qtr 2021").
-- Normalize all to standard format: Qn-YYYY
UPDATE fact_ad_revenue
SET quarter = CASE
    WHEN quarter LIKE 'Q%-____' THEN quarter                        -- already in Qn-YYYY
    WHEN quarter LIKE '____-Q%'                                     -- e.g. 2019-Q2
         THEN CONCAT('Q', SUBSTRING_INDEX(quarter,'-Q',-1), '-', SUBSTRING_INDEX(quarter,'-Q',1))
    WHEN quarter LIKE '%Qtr%'                                       -- e.g. "4th Qtr 2021"
         THEN CONCAT('Q', LEFT(quarter,1), '-', RIGHT(quarter,4))
    ELSE quarter
END;

-- ==============================================================
-- 2. FACT_PRINT_SALES CLEANING
-- ==============================================================

-- Months were inconsistent across rows: "2019/05", "Apr-19", "05-2019".
-- We standardized everything to YYYY-MM and added a DATE column.

-- Step 1: Convert formats like "2019/05" → "2019-05"
UPDATE fact_print_sales
    SET month = REPLACE(month,'/','-')
    WHERE month LIKE '____/%%';

-- Step 2: Convert formats like "Apr-19" → "04-2019"
UPDATE fact_print_sales
    SET month = CONCAT(
        CASE SUBSTRING_INDEX(month,'-',1)
            WHEN 'Jan' THEN '01'
            WHEN 'Feb' THEN '02'
            WHEN 'Mar' THEN '03'
            WHEN 'Apr' THEN '04'
            WHEN 'May' THEN '05'
            WHEN 'Jun' THEN '06'
            WHEN 'Jul' THEN '07'
            WHEN 'Aug' THEN '08'
            WHEN 'Sep' THEN '09'
            WHEN 'Oct' THEN '10'
            WHEN 'Nov' THEN '11'
            WHEN 'Dec' THEN '12'
        END,
        '-20', RIGHT(month,2)   -- expand "19" → "2019"
    )
    WHERE month REGEXP '^[A-Za-z]{3}-[0-9]{2}$';

-- Step 3: Swap formats like "04-2019" → "2019-04"
UPDATE fact_print_sales
    SET month = CONCAT(
        RIGHT(month,4), '-',    -- year
        LEFT(month,2)           -- month
    )
    WHERE month REGEXP '^[0-9]{2}-[0-9]{4}$';

-- Step 4: Add a DATE column for easy filtering (e.g., WHERE month_date BETWEEN ...)
--ALTER TABLE fact_print_sales
--ADD COLUMN IF NOT EXISTS month_date DATE;

-- Populate DATE column from standardized YYYY-MM strings
UPDATE fact_print_sales
    SET month_date = STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d');

-- Step 5: Add index on month_date for performance (time range queries)
ALTER TABLE fact_print_sales
    ADD INDEX idx_month_date (month_date);

-- ==============================================================
-- End of Cleaning Script
-- ==============================================================

