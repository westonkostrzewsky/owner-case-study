# GTM Analytics SQL

This repository contains SQL queries for analyzing GTM leads and calculating LTV:CAC metrics.

## Files

- `owner-case-study/inbound_outbound_ssot.sql` → Monthly LTV/CAC metrics by lead channel
- `owner-case-study/marketplace_metrics.sql` → LTV/CAC metrics by marketplace
- `owner-case-study/online_ordering_metrics.sql` → LTV/CAC metrics by online ordering tool
- `owner-case-study/cuisine_metrics.sql` → LTV/CAC metrics by cuisine type


## Key Findings

### 1. Channel Performance
- Outbound leads have a **significantly better LTV:CAC ratio** compared to inbound.
- Suggests focusing existing headcount or any new hiring on the **outbound team** to maximize ROI.

### 2. Cuisine Analysis
- **American** and **Italian** cuisines show the best LTV:CAC ratio for both inbound and outbound channels.

### 3. Online Ordering Platform Performance
- **Inbound:**
  - Best performing platforms: `ezCater`, `Toast Online Ordering`, `Wix Restaurants`, `Chownow`
- **Outbound:**
  - Best performing platforms: `ezCater`, `Wix Restaurants`, `Chownow`  
  - Note: `Toast Online Ordering` is less effective for outbound leads.

### 4. Marketplace Performance
- **Inbound:** `DoorDash`, `Uber Eats`, `Grubhub`, `Seamless`  
- **Outbound:** `DoorDash`, `Uber Eats`, `Grubhub`, `Seamless`, `Caviar`  

---

## Recommendations

1. **Shift focus to Outbound**
   - Reallocate existing sales headcount toward outbound efforts.
   - Prioritize new hires for the outbound team to maximize LTV:CAC ratio.

2. **Cuisine-targeted campaigns**
   - Focus marketing and sales efforts on American and Italian restaurants across channels.

3. **Platform and Marketplace Optimization**
   - Prioritize top-performing online ordering platforms for each channel.
   - Target the highest-performing marketplaces for each channel to increase conversions.

---

## Next Steps

- Explore **funnel stage conversion rates** to identify bottlenecks.
- Break down step-by-step conversion rates: form submission → first contact → demo booked → opportunity → close won.
- Calculate time to conversion and see which segments convert faster.
- Add fields to measure customer tenure (`start_date` and `end_date`), allowing for churn calculations and incorporation of $500 monthly subscription fee into LTV calculations
---
