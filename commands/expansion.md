---
description: Upsell and cross-sell opportunities — paid vs used vs unused products
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager identify expansion opportunities for an account.

## Steps

1. **Find the account:**
```sql
SELECT ID, NAME, ORG_ID, PRODUCT_LIST, ACCOUNT_FAMILY_MRR, CUSTOMER_TIER,
       SALES_SEGMENT, INDUSTRY
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one.

2. **Run these queries in parallel:**

**Product adoption (last 90 days):**
```sql
SELECT PRODUCT_GROUP,
       COUNT(DISTINCT DATADOG_USER_ID) AS ACTIVE_USERS,
       SUM(INTERACTIONS_COUNT) AS TOTAL_INTERACTIONS,
       SUM(TIME_SPENT_ON_PAGE_SECONDS) / 3600.0 AS TOTAL_HOURS
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(DAY, -90, CURRENT_DATE())
GROUP BY PRODUCT_GROUP
ORDER BY TOTAL_INTERACTIONS DESC
```

**Open opportunities:**
```sql
SELECT OPPORTUNITY_NAME, TYPE, STAGE, CLOSE_DATE
FROM REPORTING.GTM.FACT_SFDC_OPPORTUNITY_RESTRICTED_HISTORY
WHERE ACCOUNT_ID = '<sfdc_id>'
AND IS_MOST_RECENT_DATE = TRUE
AND STAGE NOT IN ('Closed Won', 'Closed Lost')
```

3. **Present an expansion analysis:**

### Current Product Footprint
- Products on contract (from PRODUCT_LIST)
- Current MRR and tier

### Cross-Sell Opportunities (not contracted, but showing usage)
For each product used but NOT in PRODUCT_LIST:
- Product name
- Active users and engagement level
- Recommendation: convert trial/free usage to paid

### Cross-Sell Opportunities (not contracted, no usage yet)
- Based on industry and segment, which Datadog products are commonly adopted by similar customers but missing here?
- Natural product pairings (e.g., APM customers often benefit from Profiling, RUM pairs with Synthetics)

### Upsell Opportunities (contracted, heavy usage)
- Products where usage is high — may be approaching plan limits or could benefit from higher tier
- Users are deeply engaged — good signal for upsell conversation

### Underutilized Products (contracted, low usage)
- Products on contract but with low engagement
- These need enablement before renewal, not expansion — but stabilizing them protects existing revenue

### In-Flight Opportunities
- Any open opportunities already in the pipeline

### Recommended Next Steps
- Prioritized list of expansion plays ranked by likelihood and revenue impact
- Suggested talking points for each opportunity
