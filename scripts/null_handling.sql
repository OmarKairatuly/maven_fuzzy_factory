-- Table website_sessions has string nulls, columns utm_source, utm_campaign, utm_content and http_referer have string nulls


use maven_fuzzy_factory

select distinct * from bronze.website_sessions
where device_type = 'NULL'

select distinct is_repeat_session from bronze.website_sessions


select distinct * from bronze.website_sessions
where utm_source IS NULL 


ALTER TABLE bronze.website_sessions
DROP COLUMN traffic_type

ALTER TABLE bronze.website_sessions
ADD channel_grouping nvarchar(50);

UPDATE bronze.website_sessions
SET channel_grouping = 
CASE WHEN utm_source != 'NULL' and http_referer != 'NULL' then 'paid_search'
	 WHEN utm_source = 'NULL' and http_referer != 'NULL' THEN 'referral'
	 else 'direct'
end 

-- Casting string NULLs in SQL NULLS

UPDATE bronze.website_sessions
SET
	utm_source = NULLIF(utm_source, 'NULL'),
	utm_content = NULLIF(utm_content, 'NULL'),
	utm_campaign = NULLIF(utm_campaign, 'NULL'),
	http_referer = NULLIF(http_referer, 'NULL');