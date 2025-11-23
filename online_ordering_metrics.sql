with lead_online as (
    select
        lead_id
      , case when form_submission_date is not null then 'inbound' else 'outbound' end as lead_channel
      , to_decimal(replace(regexp_replace(predicted_sales_with_owner, '[^0-9.,]', ''), ',', '.'), 18, 2) as predicted_sales_with_owner
      , converted_opportunity_id
      , trim(o.value::string) as online_ordering
    from demo_db.gtm_case.leads l
      , lateral flatten(input => try_parse_json(l.online_ordering_used)) o
    where o.value is not null
      and o.value::string <> ''
),

online_metrics as (
    select
        lead_channel
      , online_ordering
      , count(*) as total_leads
      , count_if(converted_opportunity_id is not null) as conversions
      , sum(predicted_sales_with_owner) as total_predicted_sales
    from lead_online
    group by 1, 2
),

channel_costs as (
    select
        'inbound' as lead_channel
      , sum(to_decimal(replace(regexp_replace(advertising, '[^0-9.,]', ''), ',', '.'), 18, 2))
        + sum(to_decimal(replace(regexp_replace(inbound_sales_team, '[^0-9.,]', ''), ',', '.'), 18, 2)) as total_allocated_cost
    from demo_db.gtm_case.expenses_advertising a
    join demo_db.gtm_case.expenses_salary_and_commissions s
      on to_date(a.month,'mon-yy') = to_date(s.month,'mon-yy')
    union all
    select
        'outbound' as lead_channel
      , sum(to_decimal(replace(regexp_replace(outbound_sales_team, '[^0-9.,]', ''), ',', '.'), 18, 2)) as total_allocated_cost
    from demo_db.gtm_case.expenses_salary_and_commissions
)

select
    o.lead_channel
  , o.online_ordering
  , total_leads
  , conversions
  , round(case when conversions = 0 then null else total_predicted_sales / conversions end, 2) as avg_ltv
  , round(case when conversions = 0 then null else ch.total_allocated_cost / conversions end, 2) as cac
  , round(case when conversions = 0 then null else total_predicted_sales / (ch.total_allocated_cost / conversions) end, 2) as ltv_cac_ratio
from online_metrics o
join channel_costs ch
  on o.lead_channel = ch.lead_channel
where conversions > 0
order by lead_channel
  , ltv_cac_ratio desc;
