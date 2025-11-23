/*
============================================================
File: marketplace_metrics.sql
Purpose: Calculates CAC, LTV, and CAC:LTV ratio for leads segmented by marketplace
Author: Weston Kostrzewsky
Date: 2025-11-22
============================================================

Description:
- Segments leads by marketplace and lead channel
- Computes total leads, conversions, predicted sales, CAC, LTV, and CAC:LTV ratio
- Rounds financial metrics to 2 decimal places
- Filters out null/empty marketplace values

Inputs:
- demo_db.gtm_case.leads
- demo_db.gtm_case.expenses_advertising
- demo_db.gtm_case.expenses_salary_and_commissions

Outputs:
- lead_channel, marketplace, total leads, conversions, avg LTV, CAC, LTV:CAC ratio
*/

with lead_marketplace as (
    select
        lead_id
      , case when form_submission_date is not null then 'inbound' else 'outbound' end as lead_channel
      , to_decimal(replace(regexp_replace(predicted_sales_with_owner, '[^0-9.,]', ''), ',', '.'), 18, 2) as predicted_sales_with_owner
      , converted_opportunity_id
      , trim(m.value::string) as marketplace
    from demo_db.gtm_case.leads l
      , lateral flatten(input => try_parse_json(l.marketplaces_used)) m
    where m.value is not null
      and m.value::string <> ''
),

marketplace_metrics as (
    select
        lead_channel
      , marketplace
      , count(*) as total_leads
      , count_if(converted_opportunity_id is not null) as conversions
      , sum(predicted_sales_with_owner) as total_predicted_sales
    from lead_marketplace
    group by 1, 2
),

channel_costs as (
    select
        'inbound' as lead_channel
      , sum(to_decimal(replace(regexp_replace(advertising, '[^0-9.,]', ''), ',', '.'), 18, 2))
        + sum(to_decimal(replace(regexp_replace(inbound_sales_team, '[^0-9.,]', ''), ',', '.'), 18, 2)) as total_allocated_cost
    from demo_db.gtm_case.expenses_advertising a
      , demo_db.gtm_case.expenses_salary_and_commissions s
    where to_date(a.month,'mon-yy') = to_date(s.month,'mon-yy')
    union all
    select
        'outbound' as lead_channel
      , sum(to_decimal(replace(regexp_replace(outbound_sales_team, '[^0-9.,]', ''), ',', '.'), 18, 2)) as total_allocated_cost
    from demo_db.gtm_case.expenses_salary_and_commissions
)

select
    m.lead_channel
  , m.marketplace
  , total_leads
  , conversions
  , round(case when conversions = 0 then null else total_predicted_sales / conversions end, 2) as avg_ltv
  , round(case when conversions = 0 then null else total_allocated_cost / conversions end, 2) as cac
  , round(case when conversions = 0 then null else total_predicted_sales / (total_allocated_cost / conversions) end, 2) as ltv_cac_ratio
from marketplace_metrics m
join channel_costs ch
  on m.lead_channel = ch.lead_channel
where conversions > 0
order by lead_channel
  , ltv_cac_ratio desc;
