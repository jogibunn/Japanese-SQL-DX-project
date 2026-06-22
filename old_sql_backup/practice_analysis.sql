-- Active: 1781602366234@@127.0.0.1@3306@india_project
-- ========== 1、切换到当前业务库，必须先执行 ==========
USE india_project;
/*
语法讲解：
USE 数据库名;
作用：指定接下来所有SQL操作都在 india_project 库里执行，不写会报找不到表
*/
SHOW TABLES;
--SHOW TABLES; 作用：列出当前数据库中的所有表，确认表已经成功导入
DESC dim_city;
-- DESDC dim_city; 作用：查看 dim_city 表的字段信息，确认表结构正确
USE india_project;
SELECT * FROM dim_city;
SELECT
    COUNT(CASE WHEN city_id IS NULL THEN 1 END) AS has_null_city_id,
    COUNT(CASE WHEN city IS NULL THEN 1 END) AS has_null_city_name,
    COUNT(CASE WHEN state IS NULL THEN 1 END) AS has_null_state,
    COUNT(CASE WHEN tier IS NULL THEN 1 END) AS has_null_region
FROM dim_city
