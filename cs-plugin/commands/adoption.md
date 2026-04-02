---
description: Product adoption analysis — which products are used, unused, and by whom
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager understand product adoption for an account.

## Steps

1. **Find the account:**
```sql
SELECT ID, NAME, ORG_ID, PRODUCT_LIST, CUSTOMER_TIER
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one.

2. **Get adoption data (last 90 days):**
```sql
SELECT PRODUCT_GROUP,
       COUNT(DISTINCT DATADOG_USER_ID) AS ACTIVE_USERS,
       SUM(INTERACTIONS_COUNT) AS TOTAL_INTERACTIONS,
       SUM(TIME_SPENT_ON_PAGE_SECONDS) / 3600.0 AS TOTAL_HOURS,
       MIN(PAGEVIEW_TIMESTAMP) AS FIRST_SEEN,
       MAX(PAGEVIEW_TIMESTAMP) AS LAST_SEEN
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(DAY, -90, CURRENT_DATE())
GROUP BY PRODUCT_GROUP
ORDER BY TOTAL_INTERACTIONS DESC
```

3. **Get week-over-week trend (last 4 weeks):**
```sql
SELECT PRODUCT_GROUP,
       DATE_TRUNC('WEEK', PAGEVIEW_TIMESTAMP) AS WEEK,
       COUNT(DISTINCT DATADOG_USER_ID) AS WEEKLY_USERS,
       SUM(INTERACTIONS_COUNT) AS WEEKLY_INTERACTIONS
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(WEEK, -4, CURRENT_DATE())
GROUP BY PRODUCT_GROUP, DATE_TRUNC('WEEK', PAGEVIEW_TIMESTAMP)
ORDER BY PRODUCT_GROUP, WEEK
```

4. **Present an adoption report:**

### Actively Used Products
- Ranked by engagement (interactions + hours)
- User count, total interactions, hours spent
- Week-over-week trend (growing, stable, declining)

### Paid but Unused Products
- Compare PRODUCT_LIST from the account record against products with actual usage
- Flag any paid products with zero or near-zero activity — these are churn risks

### Unpaid but Used Products
- Products showing usage that are NOT in PRODUCT_LIST — these are expansion opportunities

### Adoption Trend
- Which products are growing in usage vs declining
- Any products that were active but have gone quiet recently

### Recommendations
- Products to reinforce (high usage, strategic value)
- Products needing enablement (paid but low adoption)
- Expansion candidates (used but not contracted)
