---
description: Full account health briefing — health status, MRR, tier, churn risk, and flags
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager get a full health briefing on an account.

## Steps

1. **Find the account** in Snowflake:
```sql
SELECT ID, NAME, ORG_ID, SALES_SEGMENT, WORLD_REGION, EMPLOYEE_COUNT, INDUSTRY,
       ACCOUNT_STATUS, ACCOUNT_HEALTH_STATUS, HEALTH_STATUS_DETAILS, HEALTH_STATUS_DETAILS_HISTORY,
       ACCOUNT_PRIORITIZATION, ACCOUNT_FAMILY_MRR, CUSTOMER_TIER, FIRST_CLOSED_WON_DATE,
       CHURN_RISK_LIKELIHOOD, CHURN_RISK_REASON, PRODUCT_LIST, COMPETITORS,
       HAS_EB_CHAMPION_ISSUES, HAS_USAGE_CONTRACT_ISSUES, HAS_COMMUNICATION_QUALITY_ISSUES
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one. If no matches, try broader search terms.

2. **Get the account profile** using the ORG_ID from step 1:
```sql
SELECT ORG_ID, ORG_NAME, COUNT_USERS, BILLING_PLAN_CURRENT, CUSTOMER_TIER,
       ACCOUNT_OWNER_NAME, ACCOUNT_OWNER_EMAIL, SALES_ENGINEER_NAME,
       ACCOUNT_STATUS, ACCOUNT_HEALTH_STATUS, CREATION_YEAR, DAY_SINCE_CREATION
FROM REPORTING.GENERAL.ACCOUNT_PROFILE
WHERE ORG_ID = <org_id>
```

3. **Present a briefing** with these sections:

### Account Overview
- Name, industry, segment, region, employee count
- Customer since (FIRST_CLOSED_WON_DATE), days as customer
- Tier, billing plan, number of users

### Health Status
- Current health status and details
- Health status history (show trend)
- Account prioritization level

### Financial
- Current MRR
- Customer tier

### Risk Flags
- Churn risk likelihood and reason
- EB/Champion issues flag
- Usage/contract issues flag
- Communication quality issues flag

### Team
- Account owner and email
- Sales engineer

### Competitive & Product Context
- Products in use
- Known competitors

Use clear formatting with headers and bullet points. Highlight any red flags (poor health, high churn risk, flagged issues) prominently so the CSM can act on them.
