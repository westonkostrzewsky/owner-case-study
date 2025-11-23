-- normalize expense tables
-- convert cost/salary fields to numbers, removing characters and non-breaking spaces
-- convert month fields to dates
with cleaned_advertising as (
    select
        to_date(month, 'mon-yy') as month
      , to_decimal(replace(regexp_replace(advertising, '[^0-9.,]', ''), ',', '.'), 18, 2) as advertising_cost -- remove currency + spaces, convert comma to decimal
    from demo_db.gtm_case.expenses_advertising
),

cleaned_salary as (
    select
        to_date(month, 'mon-yy') as month
      , to_decimal(replace(regexp_replace(outbound_sales_team, '[^0-9.,]', ''), ',', '.'), 18, 2) as outbound_salary
      , to_decimal(replace(regexp_replace(inbound_sales_team, '[^0-9.,]', ''), ',', '.'), 18, 2) as inbound_salary
    from demo_db.gtm_case.expenses_salary_and_commissions
),

-- leads
normalized_leads as (
    select
        lead_id
      , coalesce(
            try_to_date(replace(form_submission_date, '00', '20'))
          , date_trunc('month', first_sales_call_date)
          , date_trunc('month', first_text_sent_date)
          , date_trunc('month', first_meeting_booked_date)
          , date_trunc('month', last_sales_activity_date)
        ) as lead_month
      , to_decimal(replace(regexp_replace(predicted_sales_with_owner, '[^0-9.,]', ''), ',', '.'), 18, 2) as predicted_sales_with_owner
      , marketplaces_used
      , array_size(
            filter(
                array_compact(try_parse_json(marketplaces_used)::array)
              , value -> lower(trim(value::string)) <> 'nan' and value::varchar <> ''
            )
        ) as marketplace_count
      , online_ordering_used
      , array_size(
            filter(
                array_compact(try_parse_json(online_ordering_used)::array)
              , value -> lower(trim(value::string)) <> 'nan' and value::varchar <> ''
            )
        ) as online_ordering_used_count
      , cuisine_types
      , array_size(
            filter(
                array_compact(try_parse_json(cuisine_types)::array)
              , value -> lower(trim(value::string)) <> 'nan' and value::varchar <> ''
            )
        ) as cuisine_types_count
      , location_count
      , case 
            when form_submission_date is not null then 'inbound'
            else 'outbound'
        end as lead_channel
      , converted_opportunity_id
    from demo_db.gtm_case.leads
),

-- feature engineering (row-level lead features)
lead_features as (
    select
        lead_id
      , lead_month
      , lead_channel
      , predicted_sales_with_owner
      , location_count
      , case
            when location_count is null or location_count = 0 then null
            else predicted_sales_with_owner / location_count
        end as predicted_sales_per_location
      , case when marketplace_count > 0 then 1 else 0 end as marketplace_flag
      , case when online_ordering_used_count > 0 then 1 else 0 end as online_ordering_flag
      , case when cuisine_types_count > 0 then 1 else 0 end as cuisine_types_flag
      , converted_opportunity_id
    from normalized_leads
),

-- monthly leads + ltv
monthly_lead_stats as (
    select
        date_trunc('month', lead_month) as month
      , lead_channel
      , count(*) as leads
      , count_if(converted_opportunity_id is not null) as conversions
      , sum(predicted_sales_with_owner) as total_predicted_sales_with_owner
    from lead_features
    group by 1, 2
    order by 1
),

-- complete month x channel matrix
month_channel_matrix as (
    select distinct m.month, c.lead_channel
    from (select distinct month from cleaned_advertising) m
    cross join (select distinct lead_channel from normalized_leads) c
),

monthly_finalized as (
    select
        m.month
      , m.lead_channel
      , coalesce(s.leads, 0) as leads
      , coalesce(s.conversions, 0) as conversions
      , coalesce(s.total_predicted_sales_with_owner, 0) as total_predicted_sales_with_owner
    from month_channel_matrix m
    left join monthly_lead_stats s
      on m.month = s.month
     and m.lead_channel = s.lead_channel
),

-- allocate expenses by channel
allocated_costs as (
    select
        f.*
      , case
            when lead_channel = 'inbound' then a.advertising_cost + s.inbound_salary
            when lead_channel = 'outbound' then s.outbound_salary
            else 0
        end as allocated_cost
    from monthly_finalized f
    left join cleaned_advertising a using (month)
    left join cleaned_salary s using (month)
),

-- cac, ltv, ratio metrics
final_gtm_model as (
    select
        month
      , lead_channel
      , leads
      , conversions
      , allocated_cost
      , total_predicted_sales_with_owner
      , round(iff(conversions = 0, null, allocated_cost / conversions), 2) as cac
      , round(iff(conversions = 0, null, total_predicted_sales_with_owner / conversions), 2) as avg_ltv
      , round(iff(conversions = 0, null, total_predicted_sales_with_owner / (allocated_cost / conversions)), 2) as ltv_cac_ratio
    from allocated_costs
)

-- final output
select *
from final_gtm_model
order by month, lead_channel;
