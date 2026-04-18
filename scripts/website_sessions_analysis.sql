/*
===============================================================================
-- Analyzing tables website_sessions
===============================================================================
*/


select distinct pageview_url from  bronze.website_pageviews

use maven_fuzzy_factory

select distinct utm_source from bronze.website_sessions;

select distinct * from bronze.website_sessions
where utm_source = 'NULL'

-- Calculate session volume by source and percent to total

select 
	utm_source,
	num_of_sessions,
	cast((num_of_sessions* 100.0/total_sessions) as decimal(10, 2)) percent_to_total,
	total_sessions
from (
select
	utm_source,
	count(website_session_id) num_of_sessions,
	sum(count(website_session_id)) over() total_sessions
from bronze.website_sessions
group by utm_source) t
order by num_of_sessions desc


-- Relation between tables orders and website_sessions are one to one

select 
website_session_id,
count(order_id) orders
from bronze.orders
group by website_session_id
having count(order_id) != 1
order by orders desc


-- Conversion Rate

with orders_total as (
select count(*) total_orders
from bronze.orders),
sessions_total as (
select count(*) total_sessions
from bronze.website_sessions)
select cast((o.total_orders* 100.0/w.total_sessions) as decimal(10, 2)) CVR
from orders_total o
cross join sessions_total w

-- Calculate number of orders per utm_source

select
	w.utm_source,
	count(o.order_id) orders,
	cast((count(o.order_id) * 100.0) / sum(count(o.order_id)) over () as decimal(10, 2)) 	 percent_to_total,
	sum(count(o.order_id)) over () total_orders
from bronze.orders o
left join bronze.website_sessions w
on o.website_session_id = w.website_session_id
group by w.utm_source
order by orders desc

-- Calculate The CVR per utm_source

with sessions_source as (
select
	utm_source,
	count(website_session_id) sessions
from bronze.website_sessions
group by utm_source),
orders_source as (
select
	w.utm_source utm_source,
	count(o.order_id) orders
from bronze.orders o
left join bronze.website_sessions w
on o.website_session_id = w.website_session_id
group by w.utm_source)
select 
s.utm_source,
s.sessions,
o.orders,
cast((o.orders * 100.0) / s.sessions as decimal(10, 2)) CVR_per_source
from sessions_source s
left join orders_source o
on s.utm_source = o.utm_source
order by CVR_per_source desc


-- Calculate the 'retention' and 'new people' sessions and their percents to total

select 
case when is_repeat_session = 1 then 'Retention'
     else 'Newcomers'
end as is_repeat_session,
count(website_session_id) sessions,
cast((count(website_session_id)
* 100.0) / sum(count(website_session_id)) over() as decimal(10, 2)) percent_to_total
from bronze.website_sessions
group by is_repeat_session
order by sessions

use maven_fuzzy_factory


-- Calculate the CVR of 'Retention' and 'Newcomers' sessions
with sessions_total as (
select 
case when is_repeat_session = 1 then 'Retention'
     else 'Newcomers'
end as is_repeat_session,
count(website_session_id) sessions
from bronze.website_sessions
group by is_repeat_session),
orders_total as (
select
case when w.is_repeat_session = 1 then 'Retention'
     else 'Newcomers'
end as is_repeat_session,
count(o.order_id) orders
from bronze.orders o
left join bronze.website_sessions w
on o.website_session_id = w.website_session_id
group by w.is_repeat_session)
select
s.is_repeat_session,
s.sessions,
o.orders,
cast((o.orders * 100.0) / s.sessions as decimal(10, 2)) CVR
from sessions_total s
left join orders_total o
on s.is_repeat_session = o.is_repeat_session


/*
===============================================================================
-- Analyzing tables website_sessions
===============================================================================
*/


use maven_fuzzy_factory

select distinct pageview_url from bronze.website_pageviews

/* Customer journey through pageviews:
1. Entry (Landers) and Home.
2. Products (The catalog).
3. Product Details.
4. Intent to Buy (cart).
5. Shipping & Billing.
6. Thank you for your order.
*/

-- Is home page is one of the lander pages?

select 
website_session_id sessions,
count(website_pageview_id) pageviews
from bronze.website_pageviews
where pageview_url = '/shipping'
group by website_session_id
having count(website_pageview_id) = 1
 -- IT IS

-- Is catalog page one of the landing pages?

select 
website_session_id sessions,
count(website_pageview_id) pageviews
from bronze.website_pageviews
where pageview_url = '/products'
group by website_session_id
having count(website_pageview_id) = 1

-- 





-- The number of pageviews each session has

select 
website_session_id sessions,
count(website_pageview_id) pageviews
from bronze.website_pageviews
group by website_session_id
order by pageviews desc


-- Landing page analysis. Identify which lander version is the best, calculate the Bounce Rate:
-- Bounce Rate = (Sessions with only 1 pageview / Total sessions starting on that page) * 100


with session_metrics as (
select 
	website_session_id,
	min(website_pageview_id) first_pv,
	count(website_pageview_id) pv_count
from bronze.website_pageviews
group by website_session_id
) 
select 
	wp.pageview_url landing_page,
	count(sm.website_session_id) total_sessions,
	count(case when sm.pv_count = 1 then 1 else null end) bounced_sessions,
	cast(count(case when sm.pv_count = 1 then 1 else null end) * 1.0 / count(sm.website_session_id) as decimal(10, 2)) bounce_rate
from session_metrics sm 
join bronze.website_pageviews wp
on sm.first_pv = wp.website_pageview_id
group by wp.pageview_url;


-- Funnel Drop-off Analysis
-- % of products viewers which reached cart

with catalog_viewers as (
select 
count(website_pageview_id) catalog_pages
from bronze.website_pageviews 
where pageview_url = '/products'),
cart_viewers as (
select
count(website_pageview_id) cart_pages
from bronze.website_pageviews
where pageview_url = '/cart')
select
cg.catalog_pages,
cr.cart_pages,
cast((cr.cart_pages * 100.0 / cg.catalog_pages) as decimal(10, 2)) percent_of_cart_view
from catalog_viewers cg
cross join cart_viewers cr;

with catalog_viewers as (
select distinct
website_session_id
from bronze.website_pageviews 
where pageview_url = '/products'),
cart_viewers as (
select distinct
website_session_id
from bronze.website_pageviews
where pageview_url = '/cart')
select
count(coalesce(cg.website_session_id, 0)) catolog_views,
count(cr.website_session_id) cart_views,
cast((count(cr.website_session_id) * 100.0 / nullif(count(coalesce(cg.website_session_id, 0)), 0)) as decimal(10, 2)) percent_of_cart_view
from catalog_viewers cg
left join cart_viewers cr
on cg.website_session_id = cr.website_session_id


with catalog_viewers as (
select distinct
website_session_id
from bronze.website_pageviews 
where pageview_url = '/products'),
cart_viewers as (
select distinct
website_session_id
from bronze.website_pageviews
where pageview_url = '/cart')
select
count(cg.website_session_id) catolog_views,
count(coalesce(cr.website_session_id, 0)) cart_views,
cast((count(coalesce(cr.website_session_id, 0)) * 100.0 / count(cg.website_session_id)) as decimal(10, 2)) percent_of_cart_view
from catalog_viewers cg
left join cart_viewers cr
on cg.website_session_id = cr.website_session_id

-- % of cart users reach shipping

with shipping_viewers as (
select distinct
website_session_id
from bronze.website_pageviews 
where pageview_url = '/shipping'),
cart_viewers as (
select distinct
website_session_id
from bronze.website_pageviews
where pageview_url = '/cart')
select
count(cr.website_session_id) cart_views,
count(sv.website_session_id) shipping_views,
cast((count(sv.website_session_id) * 100.0 / count(cr.website_session_id)) as decimal(10, 2)) percent_of_cart_view
from  cart_viewers cr
left join shipping_viewers sv
on cr.website_session_id = sv.website_session_id

-- % of billing users reach thank-you page

with billing_viewers as (
select distinct
website_session_id
from bronze.website_pageviews 
where pageview_url = '/billing' or pageview_url = '/billing-2'),
customers as (
select distinct
website_session_id
from bronze.website_pageviews
where pageview_url = '/thank-you-for-your-order')
select
count(bv.website_session_id) billing_views,
count(cs.website_session_id) customers,
cast((count(cs.website_session_id) * 100.0 / count(bv.website_session_id)) as decimal(10, 2)) percent_of_customers
from  billing_viewers bv
left join customers cs
on bv.website_session_id = cs.website_session_id

-- The CVR from /billing vs /billing-2 to the tahnk-you page comparison


with billing_sessions as (
select 
	website_session_id,
	pageview_url billing_seen
from bronze.website_pageviews
where pageview_url in ('/billing', '/billing-2')),
orders as (
select website_session_id
from bronze.website_pageviews
where pageview_url = '/thank-you-for-your-order'
)
select
	b.billing_seen,
	count(b.website_session_id) total_sessions,
	count(o.website_session_id) total_orders,
	cast(count(o.website_session_id) * 100.0 / count(b.website_session_id) as decimal(10, 2)) conversion_rate
from billing_sessions b
left join orders o 
on b.website_session_id = o.website_session_id 
group by b.billing_seen