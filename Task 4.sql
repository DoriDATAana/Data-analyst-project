-- BONUS --
create or replace function pg_temp.utm_temp_function (url_parameters varchar)
RETURNS varchar AS $$
BEGIN
RETURN coalesce(LOWER(substring(url_parameters, 'utm_campaign=([^#!&]+)' )),' ') as utm_campaign;
END; $$
LANGUAGE plpgsql;

-- 1 and 2 --
with facebook_google_metrics as 
(
select
	facebook_ads_basic_daily.ad_date,
	facebook_ads_basic_daily.url_parameters,
	facebook_ads_basic_daily.spend,
	facebook_ads_basic_daily.impressions,
	facebook_ads_basic_daily.reach,
	facebook_ads_basic_daily.clicks,
	facebook_ads_basic_daily.leads,
	facebook_ads_basic_daily.value
from
	facebook_ads_basic_daily
union all
select
	google_ads_basic_daily.ad_date,
	google_ads_basic_daily.url_parameters,
	google_ads_basic_daily.spend,
	google_ads_basic_daily.impressions,
	google_ads_basic_daily.reach,
	google_ads_basic_daily.clicks,
	google_ads_basic_daily.leads,
	google_ads_basic_daily.value
from
	google_ads_basic_daily
),
all_metrics as 
(
select
	ad_date,
	url_parameters,
	coalesce (spend,0) as spend, 
	coalesce (impressions,0) as impressions,
	coalesce (reach,0) as reach,
	coalesce (clicks,0) as clicks,
	coalesce (leads,0) as leads,
	coalesce (value,0) as value,
	pg_temp.utm_temp_function(url_parameters) as utm_campaign
from
	facebook_google_metrics
	)
select
	ad_date,
	case when utm_campaign ='nan' then null else utm_campaign end,
	sum(spend) as total_spend,
	sum(impressions) as number_impressions,
	sum(clicks) as number_clicks,
	sum(value) as total_value,
	case when sum(clicks) = 0 then 0 else round(sum(spend::float)/sum(clicks::float)) end as cpc, 
	case when sum(impressions) =0 then 0 else round(sum(spend::float)/sum(impressions::float)*1000) end as cpm,
	case when sum(impressions)=0 then 0 else round(sum(clicks::float)/sum(impressions::float)*100) end as ctr,
	case when sum(spend)=0 then 0 else round(((sum(value::float) - sum(spend::float))/sum(spend::float))*100) end as romi
from 
	all_metrics
group by
	all_metrics.ad_date, 
	utm_campaign;