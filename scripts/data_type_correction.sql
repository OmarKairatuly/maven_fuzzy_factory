-- ====================================================================
-- Correcting data types of columns 'refund_amount_usd', 'price_usd', 'cogs-usd' in tables 'order_item_refunds',
-- 'orders', 'order_items'. (Due to difficulties during loading dataset, those columns were loaded as 'varchar'.
-- We are going to turn those columns into decimal(10, 2), standard data type for money.
-- ====================================================================


-- ====================================================================
-- bronze.order_item_refunds

-- Checking convertibility:
-- Expectation: No Results

SELECT refund_amount_usd
FROM bronze.order_item_refunds
WHERE refund_amount_usd IS NOT NULL
      AND TRY_CAST(refund_amount_usd AS DECIMAL(10, 2)) IS NULL;

-- Converting and dropping old columns

ALTER TABLE bronze.order_item_refunds
ADD refund_amount_usd_num DECIMAL(10, 2);

UPDATE bronze.order_item_refunds
SET refund_amount_usd_num = TRY_CAST(refund_amount_usd AS DECIMAL(10, 2));

ALTER TABLE bronze.order_item_refunds
DROP COLUMN refund_amount_usd;

EXEC sp_rename
'bronze.order_item_refunds.refund_amount_usd_num',
'refund_amount_usd',
'COLUMN';

-- ====================================================================
-- 'bronze.order_items'


-- Checking convertibility:
-- Expectation: No Results

SELECT price_usd
FROM bronze.order_items
WHERE price_usd IS NOT NULL
      AND TRY_CAST(price_usd AS DECIMAL(10, 2)) IS NULL;

SELECT cogs_usd
FROM bronze.order_items
WHERE cogs_usd IS NOT NULL
      AND TRY_CAST(cogs_usd AS DECIMAL(10, 2)) IS NULL;

-- Converting

ALTER TABLE bronze.order_items
ADD 
    price_usd_num DECIMAL(10, 2),
    cogs_usd_num DECIMAL(10, 2);

UPDATE bronze.order_items
SET 
    price_usd_num = TRY_CAST(price_usd AS DECIMAL(10, 2)),
    cogs_usd_num = TRY_CAST(cogs_usd AS DECIMAL(10, 2));

-- Verification

SELECT 
    price_usd,
    price_usd_num,
    cogs_usd,
    cogs_usd_num
FROM bronze.order_items;

-- Dropping old columns & renaming new ones

ALTER TABLE bronze.order_items
DROP COLUMN price_usd, cogs_usd;

EXEC sp_rename
'bronze.order_items.price_usd_num',
'price_usd',
'COLUMN';

EXEC sp_rename
'bronze.order_items.cogs_usd_num',
'cogs_usd',
'COLUMN';

-- ====================================================================
-- 'bronze.orders'

-- Checking convertibility:
-- Expectation: No Results

SELECT price_usd
FROM bronze.orders
WHERE price_usd IS NOT NULL
      AND TRY_CAST(price_usd AS DECIMAL(10, 2)) IS NULL;

SELECT cogs_usd
FROM bronze.orders
WHERE cogs_usd IS NOT NULL
      AND TRY_CAST(cogs_usd AS DECIMAL(10, 2)) IS NULL;

-- Converting

ALTER TABLE bronze.orders
ADD 
    price_usd_num DECIMAL(10, 2),
    cogs_usd_num DECIMAL(10, 2);

UPDATE bronze.orders
SET
    price_usd_num = TRY_CAST(price_usd AS DECIMAL(10, 2)),
    cogs_usd_num = TRY_CAST(cogs_usd AS DECIMAL(10, 2));

-- Verification

SELECT 
    price_usd,
    price_usd_num,
    cogs_usd,
    cogs_usd_num
FROM bronze.orders;

-- Dropping old columns & renaming new ones

ALTER TABLE bronze.orders
DROP COLUMN price_usd, cogs_usd;

EXEC sp_rename
'bronze.orders.price_usd_num',
'price_usd',
'COLUMN';

EXEC sp_rename
'bronze.orders.cogs_usd_num',
'cogs_usd',
'COLUMN';