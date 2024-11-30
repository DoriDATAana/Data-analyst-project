-- 1 and 2 --
select ad_date, campaign_id, 
sum(spend) as total_cost, 
sum (impressions) as impressions_number, 
sum (clicks) as clicks_number, 
sum (value) as total_value,
round(sum(spend::float)/sum(clicks::float)) as CPC, 
round(sum(spend::float)/sum(impressions::float)*1000) as CPM,
round(sum(clicks::float)/sum(impressions::float)*100) as CTR,
round(((sum(value::float)-sum(spend::float))/sum(spend::float)))*100 as ROMI
from facebook_ads_basic_daily
where clicks>0
group by ad_date, campaign_id, spend;


--BONUS--

select campaign_id, sum(spend), round(((sum(value::float)-sum(spend::float))/sum(spend::float))*100) as ROMI
from facebook_ads_basic_daily
group by campaign_id
having sum(spend) > 500000
order by ROMI desc
limit 1;