 use maven_fuzzy_factory

/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/





-- Compute the total revenue generated and refunded amount and the percent of refunded amount to total revenue
-- use maven_fuzzy_factory

/* wrong query logic
select 
sum(o.price_usd - o.cogs_usd) total_revenue_orders,
sum(i.price_usd - i.cogs_usd) total_revenue_items,
sum(o.price_usd - o.cogs_usd) - sum(i.price_usd - i.cogs_usd) diff
from bronze.orders o
left join bronze.order_items i
on o.order_id = i.order_id; */

with orders_total as (
select sum(price_usd - cogs_usd) rev from bronze.orders),
items_total as (
select sum(price_usd - cogs_usd) rev from bronze.order_items),
refunds_total as (
select sum(refund_amount_usd) refund from bronze.order_item_refunds)
select 
o.rev total_rev_orders,
i.rev total_rev_items,
r.refund total_refund,
o.rev - r.refund net_total_revenue,
cast((r.refund / o.rev) * 100 as decimal(10, 2)) percent_of_refund_amount
from orders_total o
cross join items_total i
cross join refunds_total r;
/*
===============================================================================
-- Rank the users by generated revenue
===============================================================================
*/

-- Rank the users by generated revenue

select 
user_id,
sum(price_usd - cogs_usd) total_rev
from bronze.orders
group by user_id
order by total_rev desc

-- Total net revenue by simple aggregation

select
sum(o.price_usd - o.cogs_usd) - sum(coalesce(r.refund_amount_usd, 0)) total_net_rev
from bronze.orders o
left join bronze.order_item_refunds r
on o.order_id = r.order_id;

-- Total net revenue by separate aggregation

with net_ref as (
select 
order_id,
sum(refund_amount_usd) refund
from bronze.order_item_refunds
group by order_id),
net_rev as (
select 
order_id,
sum(price_usd - cogs_usd)  rev
from bronze.orders
group by order_id)
select 
sum(v.rev) - sum(coalesce(f.refund, 0)) total_net
from net_rev v
left join net_ref f
on v.order_id = f.order_id

-- Total net revenue by separate aggregation and simple aggregation and the difference

with net_ref as (
select 
order_id,
sum(refund_amount_usd) refund
from bronze.order_item_refunds
group by order_id),
sep_aggr_net as (
select 
order_id,
sum(price_usd - cogs_usd)  rev
from bronze.orders
group by order_id),
simple_aggr_net as(
select
o.order_id,
sum(o.price_usd - o.cogs_usd) - sum(coalesce(r.refund_amount_usd, 0)) total_net_rev
from bronze.orders o
left join bronze.order_item_refunds r
on o.order_id = r.order_id
group by o.order_id)
select 
sum(s.rev) - sum(coalesce(f.refund, 0)) sep_total_net,
sum(m.total_net_rev) sim_total_net,
sum(m.total_net_rev) - (sum(s.rev) - sum(coalesce(f.refund, 0))) diff
from sep_aggr_net s
left join net_ref f
on s.order_id = f.order_id
left join simple_aggr_net m
on s.order_id = m.order_id

-- Orders which were refunded for 2 items

select 
order_id,
count(order_item_id) items,
sum(refund_amount_usd) refund_amount
from bronze.order_item_refunds
group by order_id
having count(order_item_id) > 1

-- The rev from the orders which had refund for two items

with two_items as (
select 
order_id,
count(order_item_id) items,
sum(refund_amount_usd) refund_amount
from bronze.order_item_refunds
group by order_id
having count(order_item_id) > 1),
just_rev as (
select 
order_id,
sum(price_usd - cogs_usd) rev
from bronze.orders
group by order_id)
select 
sum(j.rev)
from just_rev j
inner join two_items t
on j.order_id = t.order_id


-- The refund amount of orders which had two items refunded

with two_items as (
select 
order_id,
count(order_item_id) items,
sum(refund_amount_usd) refund_amount
from bronze.order_item_refunds
group by order_id
having count(order_item_id) > 1)
select 
sum(refund_amount) / 2 diff
from two_items

-- Net rev per user computed by separate aggregiation -- CORRECT

select
o.user_id,
sum(o.price_usd - o.cogs_usd) - coalesce(sum(r.total_refund), 0) net_rev
from bronze.orders o
left join ( -- group refunds by order_id
select order_id,
 sum(refund_amount_usd) total_refund
 from bronze.order_item_refunds
 group by order_id
 ) r on o.order_id = r.order_id
 group by o.user_id
 order by net_rev 

 -- Checking the result of net rev per user by sep aggr by summing

 select 
 sum(net_rev) total_net
 from ( 
 select
o.user_id,
sum(o.price_usd - o.cogs_usd) - coalesce(sum(r.total_refund), 0) net_rev
from bronze.orders o
left join ( -- group refunds by order_id
select order_id,
 sum(refund_amount_usd) total_refund
 from bronze.order_item_refunds
 group by order_id
 ) r on o.order_id = r.order_id
 group by o.user_id) t -- the result is correct

 -- Net rev per user computed by simple aggregiation  -- WRONG

select
o.user_id users,
sum((o.price_usd - o.cogs_usd) - coalesce(r.refund_amount_usd, 0)) net_rev
from bronze.orders o
left join bronze.order_item_refunds r
on o.order_id = r.order_id
group by o.user_id
order by net_rev

-- Checking the result of net rev per user by sep aggr by summing 

select sum(net_rev) from (
select
o.user_id users,
sum((o.price_usd - o.cogs_usd) - coalesce(r.refund_amount_usd, 0)) net_rev
from bronze.orders o
left join bronze.order_item_refunds r
on o.order_id = r.order_id
group by o.user_id) t


-- Number of orders that were refunded and their percent to total

select 
count(o.order_id) num_orders,
count(r.order_id) num_orders_refunded,
cast((count(r.order_id) * 1.00 / count(o.order_id) * 1.00) * 100.00 as decimal(10, 2)) percent_refund
from bronze.orders o
left join bronze.order_item_refunds r
on o.order_id = r.order_id;

-- Calculate the refund amount for each product

select
i.product_id,
sum(r.refund_amount_usd) refund
from bronze.order_items i
left join bronze.order_item_refunds r
on i.order_item_id = r.order_item_id
group by i.product_id
order by refund desc

-- Calculate the refund amount for each product by name

select
p.product_name,
sum(r.refund_amount_usd) refund
from bronze.order_items i
left join bronze.order_item_refunds r
on i.order_item_id = r.order_item_id
left join bronze.products p
on i.product_id = p.product_id
group by p.product_name
order by refund desc

-- Rank the products by generated revenue and percent of contribution of each product to total sales and the total sales:


with items_total as (
select sum(price_usd - cogs_usd) rev from bronze.order_items)
select 
p.product_name,
sum(i.price_usd - i.cogs_usd)  total_revenue,
cast(round((sum(i.price_usd - i.cogs_usd) / t.rev) * 100.00, 2) as decimal(10, 2))  prcnt,
t.rev total_revenue,
rank() over(order by sum(i.price_usd - i.cogs_usd) desc) ranked_products
from bronze.products p
left join bronze.order_items i
on i.product_id = p.product_id
cross join items_total t
group by 
p.product_name,
t.rev; -- t.rev is constant, and is identical for every row, cannot create new groups

-- Calculate the net rev by each product considering the refund
use maven_fuzzy_factory

with prod_refunds as (
select
p.product_name product_name,
sum(i.price_usd - i.cogs_usd) rev,
sum(r.refund_amount_usd) refund_amount
from bronze.order_items i
left join bronze.order_item_refunds r
on i.order_item_id = r.order_item_id
left join bronze.products p
on i.product_id = p.product_id
group by p.product_name)
select 
product_name,
rev,
refund_amount,
rev - refund_amount net_rev -- Correct net rev by products
from prod_refunds
order by rev desc

-- Which product has more refund in relational comparison:

with prod_refunds as (
select
p.product_name product_name,
sum(i.price_usd - i.cogs_usd) rev,
sum(r.refund_amount_usd) refund_amount
from bronze.order_items i
left join bronze.order_item_refunds r
on i.order_item_id = r.order_item_id
left join bronze.products p
on i.product_id = p.product_id
group by p.product_name)
select 
product_name,
rev,
refund_amount,
rev - refund_amount net_rev, -- Correct net rev by products
cast((refund_amount / rev) * 100 as decimal(10, 2)) refund_prcnt
from prod_refunds
order by refund_prcnt desc


