---
description: Top users by activity, products they use, and time spent
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager identify power users and champions at an account.

## Steps

1. **Find the account:**
```sql
SELECT ID, NAME, ORG_ID
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one.

2. **Get top users by activity (last 90 days):**
```sql
SELECT DATADOG_USER_ID,
       COUNT(DISTINCT PRODUCT_GROUP) AS PRODUCTS_USED,
       SUM(INTERACTIONS_COUNT) AS TOTAL_INTERACTIONS,
       SUM(TIME_SPENT_ON_PAGE_SECONDS) / 3600.0 AS TOTAL_HOURS,
       MIN(PAGEVIEW_TIMESTAMP) AS FIRST_SEEN,
       MAX(PAGEVIEW_TIMESTAMP) AS LAST_SEEN
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(DAY, -90, CURRENT_DATE())
GROUP BY DATADOG_USER_ID
ORDER BY TOTAL_INTERACTIONS DESC
LIMIT 20
```

3. **Get product breakdown for top users:**
```sql
SELECT DATADOG_USER_ID, PRODUCT_GROUP,
       SUM(INTERACTIONS_COUNT) AS INTERACTIONS,
       SUM(TIME_SPENT_ON_PAGE_SECONDS) / 3600.0 AS HOURS
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(DAY, -90, CURRENT_DATE())
AND DATADOG_USER_ID IN (<top_user_ids_from_step_2>)
GROUP BY DATADOG_USER_ID, PRODUCT_GROUP
ORDER BY DATADOG_USER_ID, INTERACTIONS DESC
```

4. **Present a power users report:**

### Top Users (ranked by engagement)
For each user show:
- User ID (email or identifier)
- Number of products used
- Total interactions and hours in last 90 days
- Last active date
- Primary products (top 3 by usage)

### Product Champions
- Group users by their primary product — these are your go-to contacts for each product area
- Identify users who span multiple products (broad champions vs. deep specialists)

### Engagement Patterns
- Are power users increasing or decreasing activity?
- Any previously active users who have gone quiet? (potential champion loss)

### Recommendations
- Who to engage as champions for renewal/expansion conversations
- Which product areas have strong internal advocates vs. weak adoption
