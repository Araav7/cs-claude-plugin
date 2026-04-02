---
description: Churn risk analysis — risk score, reasons, and trend correlation
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager assess churn risk for an account.

## Steps

1. **Find the account:**
```sql
SELECT ID, NAME, ORG_ID, ACCOUNT_HEALTH_STATUS, HEALTH_STATUS_DETAILS, HEALTH_STATUS_DETAILS_HISTORY,
       CHURN_RISK_LIKELIHOOD, CHURN_RISK_REASON, ACCOUNT_FAMILY_MRR, CUSTOMER_TIER,
       PRODUCT_LIST, COMPETITORS,
       HAS_EB_CHAMPION_ISSUES, HAS_USAGE_CONTRACT_ISSUES, HAS_COMMUNICATION_QUALITY_ISSUES
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one.

2. **Run these queries in parallel:**

**MRR trend (last 12 months):**
```sql
SELECT DATE, ACCOUNT_FAMILY_MRR
FROM REPORTING.GENERAL.FACT_SALESFORCE_ACCOUNT_HISTORY
WHERE ID = '<sfdc_id>'
AND DATE >= DATEADD(MONTH, -12, CURRENT_DATE())
AND DAY(DATE) = 1
ORDER BY DATE
```

**Adoption trend (last 90 days, weekly):**
```sql
SELECT DATE_TRUNC('WEEK', PAGEVIEW_TIMESTAMP) AS WEEK,
       COUNT(DISTINCT DATADOG_USER_ID) AS WEEKLY_USERS,
       COUNT(DISTINCT PRODUCT_GROUP) AS PRODUCTS_USED,
       SUM(INTERACTIONS_COUNT) AS WEEKLY_INTERACTIONS
FROM REPORTING.GENERAL.FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY
WHERE ORG_ID = <org_id>
AND PAGEVIEW_TIMESTAMP >= DATEADD(DAY, -90, CURRENT_DATE())
GROUP BY DATE_TRUNC('WEEK', PAGEVIEW_TIMESTAMP)
ORDER BY WEEK
```

**Contracts (upcoming renewals):**
```sql
SELECT CONTRACT_NAME, STATUS, END_DATE, DRAWDOWN_REMAINING_BALANCE
FROM REPORTING.GTM.FACT_SFDC_CONTRACT_RESTRICTED_HISTORY
WHERE ACCOUNT_ID = '<sfdc_id>'
AND IS_MOST_RECENT_DATE = TRUE
ORDER BY END_DATE
```

3. **Present a churn risk assessment:**

### Risk Summary
- Churn risk likelihood and stated reason
- Health status and details
- Overall risk rating: HIGH / MEDIUM / LOW (your assessment combining all signals)

### Risk Signals
- **Champion/EB issues:** flag if HAS_EB_CHAMPION_ISSUES is true
- **Usage vs contract mismatch:** flag if HAS_USAGE_CONTRACT_ISSUES is true
- **Communication quality:** flag if HAS_COMMUNICATION_QUALITY_ISSUES is true
- **MRR trend:** is MRR declining month-over-month?
- **Adoption trend:** are active users or interactions declining week-over-week?
- **Competitor presence:** who are the known competitors?

### MRR Trajectory
- 12-month MRR trend with % change
- Flag any months with significant drops

### Engagement Trajectory
- Weekly active users and interaction trend
- Flag declining engagement

### Contract Exposure
- Upcoming renewal dates
- Remaining drawdown balance

### Action Plan
- Prioritized list of recommended actions based on the specific risk signals identified
- Immediate actions (this week) vs. strategic actions (this quarter)
