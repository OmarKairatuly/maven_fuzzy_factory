/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'bronze' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

===============================================================================
*/

-- ====================================================================
-- Checking 'bronze.order_item_refunds'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT 
    order_item_refund_id,
    COUNT(*)
FROM bronze.order_item_refunds
GROUP BY order_item_refund_id
HAVING COUNT(*) > 1 or order_item_refund_id is null

-- Check for null values in entire table
-- Expectation: No Results

SELECT 
    created_at, order_item_id, order_id, refund_amount_usd
FROM bronze.order_item_refunds
WHERE created_at IS NULL OR order_item_id IS NULL OR order_id iS NULL OR refund_amount_usd IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT 
    refund_amount_usd 
FROM bronze.order_item_refunds;


-- ====================================================================
-- Checking 'bronze.order_items'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

select 
    order_item_id,
    COUNT(*)
from bronze.order_items
group by order_item_id
having COUNT(*) > 1 or order_item_id is null


-- Data Standardization & Consistency
SELECT DISTINCT
    price_usd 
FROM bronze.order_items


SELECT DISTINCT
    cogs_usd 
FROM bronze.order_items

-- Check for null values in entire table
-- Expectation: No Results

SELECT 
    created_at, product_id, order_id, is_primary_item, price_usd, cogs_usd
FROM bronze.order_items
WHERE created_at IS NULL OR product_id IS NULL OR order_id iS NULL OR is_primary_item IS NULL OR price_usd IS NULL OR cogs_usd IS NULL;


-- Data Standardization & Consistency
SELECT DISTINCT 
    is_primary_item 
FROM bronze.order_items;

SELECT DISTINCT 
    price_usd 
FROM bronze.order_items;

SELECT DISTINCT 
    cogs_usd 
FROM bronze.order_items;

--use maven_fuzzy_factory

-- ====================================================================
-- Checking 'bronze.orders'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results

SELECT 
    order_id,
    COUNT(*)
FROM bronze.orders
GROUP BY order_id
HAVING COUNT(*) > 1 OR order_id IS NULL


-- Check for null values in entire table
-- Expectation: No Results

SELECT 
    created_at, website_session_id, user_id, primary_product_id, order_id, items_purchased, price_usd, cogs_usd
FROM bronze.orders
WHERE created_at IS NULL OR website_session_id IS NULL OR user_id IS NULL OR primary_product_id IS NULL OR items_purchased iS NULL OR 
    price_usd IS NULL OR cogs_usd IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
-- Spaces are only possible in string columns

-- ====================================================================
-- Checking 'bronze.products'
-- ====================================================================

-- Check for Unwanted Spaces
-- Expectation: No Results

SELECT 
    product_name 
FROM bronze.products
WHERE product_name != TRIM(product_name);

-- ====================================================================
-- Checking 'bronze.website_pageviews'
-- ====================================================================

-- Check for null values in entire table
-- Expectation: No Results

SELECT 
    created_at, website_session_id, pageview_url
FROM bronze.website_pageviews
WHERE created_at IS NULL OR website_session_id IS NULL OR pageview_url IS NULL

-- Data Standardization & Consistency
 SELECT DISTINCT 
    pageview_url 
 FROM bronze.website_pageviews

 -- Check for Unwanted Spaces
-- Expectation: No Results

SELECT 
    pageview_url 
FROM bronze.website_pageviews
WHERE pageview_url != TRIM(pageview_url);

-- ====================================================================
-- Checking 'bronze.website_sessions'
-- ====================================================================

-- Check for null values in entire table
-- Expectation: No Results

SELECT 
    created_at, user_id, is_repeat_session, utm_source, utm_campaign, utm_content, device_type, http_referer
FROM bronze.website_sessions
WHERE created_at IS NULL OR user_id IS NULL OR is_repeat_session IS NULL OR utm_source IS NULL OR utm_campaign IS NULL OR 
    utm_content IS NULL OR device_type IS NULL OR http_referer IS NULL