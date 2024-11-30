with facebook_google_metrics as 
(
select  
facebook_ads_basic_daily.ad_date, 
facebook_campaign.campaign_name,
facebook_ads_basic_daily.spend, 
facebook_ads_basic_daily.impressions, 
facebook_ads_basic_daily.reach, 
facebook_ads_basic_daily.clicks, 
facebook_ads_basic_daily.leads, 
facebook_ads_basic_daily.value
from 
facebook_ads_basic_daily
inner join 
facebook_adset on facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
inner join 
facebook_campaign on facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id 
union all
SELECT 
google_ads_basic_daily.ad_date, 
google_ads_basic_daily.campaign_name, 
google_ads_basic_daily.spend, 
google_ads_basic_daily.impressions, 
google_ads_basic_daily.reach, 
google_ads_basic_daily.clicks, 
google_ads_basic_daily.leads, 
google_ads_basic_daily.value
FROM 
google_ads_basic_daily
),
total_metrics as 
(
select ad_date, campaign_name, spend, impressions, reach, clicks, leads, value
from facebook_google_metrics
)
select 
ad_date,
campaign_name,
sum (spend) as total_cost, 
sum(impressions) as impressions_number, 
sum(clicks) as clicks_number, 
sum(value) as conversion_value
from total_metrics
group by ad_date, campaign_name;

-- BONUS --

with metrics as 
(
select  
facebook_ads_basic_daily.ad_date, 
facebook_campaign.campaign_name,
facebook_adset.adset_name,
facebook_ads_basic_daily.spend, 
facebook_ads_basic_daily.impressions, 
facebook_ads_basic_daily.reach, 
facebook_ads_basic_daily.clicks, 
facebook_ads_basic_daily.leads, 
facebook_ads_basic_daily.value
from 
facebook_ads_basic_daily
inner join 
facebook_adset on facebook_adset.adset_id = facebook_ads_basic_daily.adset_id
inner join 
facebook_campaign on facebook_campaign.campaign_id = facebook_ads_basic_daily.campaign_id 
union all
SELECT 
google_ads_basic_daily.ad_date, 
google_ads_basic_daily.campaign_name, 
google_ads_basic_daily.adset_name,
google_ads_basic_daily.spend, 
google_ads_basic_daily.impressions, 
google_ads_basic_daily.reach, 
google_ads_basic_daily.clicks, 
google_ads_basic_daily.leads, 
google_ads_basic_daily.value
FROM 
google_ads_basic_daily
),
conditional_metrics as 
(
select adset_name, sum(value) as total_value, ((sum(value::float)-sum(spend::float))/sum(spend::float))*100 as ROMI
from metrics
group by adset_name
having sum(spend) > 500000
order by romi desc
)
select adset_name, ROMI
from conditional_metrics
where ROMI = (select max(ROMI) from conditional_metrics);

