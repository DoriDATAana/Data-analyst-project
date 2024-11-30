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
	case
                       when lower(substring(url_parameters,'utm_campaign=([^\&]+)')) = 'nan' then null
                       when lower(substring(url_parameters,'utm_campaign=([^\&]+)')) = '' then null
                       else lower(substring(url_parameters,'utm_campaign=([^\&]+)'))
           end as utm_campaign
from
	facebook_google_metrics
	),
monthly_metrics as 
(
select
	date_trunc ('month',
	ad_date) as ad_month,
	utm_campaign,
	sum(spend) as total_spend,
	sum(impressions) as number_impressions,
	sum(clicks) as number_clicks,
	sum(value) as total_value,
	case
		when sum(clicks) > 0 then sum(spend::float)/ sum(clicks::float)
	end as cpc, 
	case
		when sum(impressions) > 0 then sum(spend::float)/ sum(impressions::float)* 1000
	end as cpm,
	case
		when sum(impressions) > 0 then sum(clicks::float)/ sum(impressions::float)* 100
	end as ctr,
	case
		when sum(spend) > 0 then ((sum(value::float) - sum(spend::float))/ sum(spend::float))* 100
	end as romi
from 
	all_metrics
group by
	all_metrics.ad_date, 
	utm_campaign
	),
monthly_metrics_changes as 
(
select 
	*,
	lag(cpm) over (partition by utm_campaign
order by
	ad_month desc) as previous_month_cpm,
	lag(ctr) over (partition by utm_campaign
order by
	ad_month desc) as previous_month_ctr,
	lag(romi) over (partition by utm_campaign
order by
	ad_month desc) as previous_month_romi
from
	monthly_metrics
)
select
	*,
	case
		when previous_month_cpm > 0 then (cpm::numeric / previous_month_cpm) -1
	end as cpm_difference,
	case
		when previous_month_ctr > 0 then (ctr::numeric / previous_month_ctr) -1
	end as ctr_difference,
	case
		when previous_month_romi > 0 then (romi::numeric / previous_month_romi) -1
	end as romi_difference
from
	monthly_metrics_changes;