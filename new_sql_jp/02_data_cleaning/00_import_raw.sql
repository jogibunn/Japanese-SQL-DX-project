

--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
--【処理目的】ローカルフォルダ内の未加工CSVをMySQLに読み込む
--入力ソース：プロジェクト配下Databaseフォルダの未加工CSV
--出力結果：欠損値・文字化け・不統一文字列が含まれるテーブル群
--実行順位：全分析工程の一番最初、クレンジング前に必ず実行
--補足：DROP TABLE IF EXISTSで古いテーブルを削除し、重複エラーを回避する
--＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

USE India_project;

-- -------------------------------------------------------------------
--１.都市マスタテーブルdim_cityの作成
-- -------------------------------------------------------------------
DROP TABLE IF EXISTS dim_city;
CREATE TABLE dim_city (
    city_id TEXT,
    city TEXT,
    state TEXT,
    tier TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ローカル生CSVから原始データをロード（文字化け・空白欠損が保持される）
LOAD DATA INFILE 'C:/Users/chang/Desktop/IT Study/code_basics_rpc17-main digital transformation/code_basics_rpc17-main/Datasets/dim_city.csv'
INTO TABLE dim_city
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------
-- 2. 広告カテゴリマスタ dim_ad_category 作成・生データ読み込み
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS dim_ad_category;
CREATE TABLE dim_ad_category (
    ad_category_id TEXT,
    standard_ad_category TEXT,
    category_group TEXT,
    example_brands TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE 'C:/Users/chang/Desktop/IT Study/code_basics_rpc17-main digital transformation/code_basics_rpc17-main/Datasets/dim_ad_category.csv'
INTO TABLE dim_ad_category
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------
-- 3. 印刷実績ファクトテーブル fact_print_sales
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS fact_print_sales;
CREATE TABLE fact_print_sales (
   edition_id TEXT,
    city_id TEXT,
    language TEXT,
    state TEXT,
    month TEXT,
    copies_sold INT,
    copies_returned INT,
    net_circulation INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE 'C:/Users/chang/Desktop/IT Study/code_basics_rpc17-main digital transformation/code_basics_rpc17-main/Datasets/fact_print_sales.csv'
INTO TABLE fact_print_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
IGNORE 1 ROWS;

-- ------------------------------
-- 4. 広告収益実績 fact_ad_revenue
-- ------------------------------
DROP TABLE IF EXISTS fact_ad_revenue;
CREATE TABLE fact_ad_revenue (
    edition_id TEXT,
    ad_category TEXT,
    quarter TEXT,
    currency TEXT,
    comments TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE 'C:/Users/chang/Desktop/IT Study/code_basics_rpc17-main digital transformation/code_basics_rpc17-main/Datasets/fact_ad_revenue.csv'
INTO TABLE fact_ad_revenue
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;

-- ------------------------------
-- 5. 都市デジタル適応度 fact_city_readiness
-- ------------------------------
DROP TABLE IF EXISTS fact_city_readiness;
CREATE TABLE fact_city_readiness (
    row_serial TEXT, -- CSV一番目の無名列（Excel行番号）
    city_id TEXT,
    quarter TEXT,
    literacy_rate DECIMAL(5,2),
    smartphone_penetration DECIMAL(5,2),
    internet_penetration DECIMAL(5,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE 'C:/Users/chang/Desktop/IT Study/code_basics_rpc17-main digital transformation/code_basics_rpc17-main/Datasets/fact_city_readiness.csv'
INTO TABLE fact_city_readiness
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;


DROP TABLE IF EXISTS fact_digital_pilot;
CREATE TABLE fact_digital_pilot (
    row_serial TEXT, -- CSV一番目の無名冗長列（Excel行番号）
    platform TEXT,
    launch_month TEXT,
    ad_category_id TEXT,
    dev_cost INT,
    marketing_cost INT,
    users_reached INT,
    downloads_or_accesses INT,
    avg_bounce_rate DECIMAL(5,2),
    cumulative_feedback_from_customers TEXT,
    city_id TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOAD DATA INFILE 'C:/Users/chang/Desktop/IT Study/code_basics_rpc17-main digital transformation/code_basics_rpc17-main/Datasets/fact_digital_pilot.csv'
INTO TABLE fact_digital_pilot
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 ROWS;
