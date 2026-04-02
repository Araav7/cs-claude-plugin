---
description: Renewal preparation — contracts, MRR trend, adoption, and open opportunities
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager prepare for an account renewal.

## Steps

1. **Find the account:**
```sql
SELECT ID, NAME, ORG_ID, ACCOUNT_FAMILY_MRR, CUSTOMER_TIER, ACCOUNT_HEALTH_STATUS,
       CHURN_RISK_LIKELIHOOD, CHURN_RISK_REASON, PRODUCT_LIST, COMPETITORS
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one.

2. **Run these queries in parallel** using the ID and ORG_ID from step 1:

**Contracts:**
```sql
SELECT CONTRACT_ID, CONTRACT_NAME, STATUS, PLAN_TYPE, START_DATE, END_DATE,
       YEAR_1_CONTRACT_FEE, DRAWDOWN_REMAINING_BALANCE
FROM REPORTING.GTM.FACT_SFDC_CONTRACT_RESTRICTED_HISTORY
WHERE ACCOUNT_ID = '<sfdc_id>'
AND IS_MOST_RECENT_DATE = TRUE
ORDER BY END_DATE DESC
```

**MRR trend (last 12 months, sampled monthly):**
```sql
SELECT DATE, ACCOUNT_FAMILY_MRR
FROM REPORTING.GENERAL.FACT_SALESFORCE_ACCOUNT_HISTORY
WHERE ID = '<sfdc_id>'
AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE())
AND DAY(DATE) = 1
ORDER BY DATE
```

**Open opportunities:**
```sql
SELECT OPPORTUNITY_NAME, TYPE, STAGE, CLOSE_DATE, NEXT_STEP
FROM REPORTING.GTM.FACT_SFDC_OPPORTUNITY_RESTRICTED_HISTORY
WHERE ACCOUNT_ID = '<sfdc_id>'
AND IS_MOST_RECENT_DATE = TRUE
AND STAGE NOT IN ('Closed Won', 'Closed Lost')
ORDER BY CLOSE_DATE
```

**Product adoption (last 90 days):**
```sql
SELECT PRODUCT_GROUP, COUNT(DISTINCT DATADOG_USER_ID) AS ACTIVE_USERS,
       SUM(INTERACTIONS_COUNT) AS TOTAL_INTERACTIONS,
       SUM(TIME_SPENT_ON_PAGE_SECONDS) / 3600.0 AS TOTAL_HOURS
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(DAY, -90, CURRENT_DATE())
GROUP BY PRODUCT_GROUP
ORDER BY TOTAL_INTERACTIONS DESC
```

3. **Present a renewal briefing** with these sections:

### Contract Summary
- Active contracts with start/end dates and fees
- Drawdown remaining balance
- Days until nearest renewal

### MRR Trend
- Month-by-month MRR for the last 12 months
- Highlight growth or contraction (calculate % change)

### Product Adoption
- Products actively used (with user counts and engagement hours)
- Products on contract (from PRODUCT_LIST) but NOT showing usage — flag these as risk
- Products showing usage but NOT on contract — flag these as expansion opportunities

### Open Opportunities
- Any in-flight deals, stages, and expected close dates

### Risk & Leverage
- Churn risk level and reason
- Health status
- Competitors in play
- Recommendations: what to highlight in the renewal conversation, what risks to address

Format as an actionable brief the CSM can walk into a renewal meeting with.
