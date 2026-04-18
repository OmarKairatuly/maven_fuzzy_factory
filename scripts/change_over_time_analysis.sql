/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Analyse sales performance over time
-- Quick Date Functions

SELECT
    YEAR(created_at) AS order_year,
    MONTH(created_at) AS order_month,
    SUM(price_usd - cogs_usd) AS total_sales,
    COUNT(DISTINCT user_id) AS total_customers,
    SUM(items_purchased) AS total_quantity
FROM bronze.orders
GROUP BY YEAR(created_at), MONTH(created_at)
ORDER BY YEAR(created_at), MONTH(created_at);