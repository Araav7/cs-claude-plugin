---
description: MRR trend over 12-24 months, month by month
arguments:
  - name: customer
    description: Customer/account name to look up
    required: true
---

You are helping a Customer Success manager review MRR trends for an account.

## Steps

1. **Find the account:**
```sql
SELECT ID, NAME, ACCOUNT_FAMILY_MRR, CUSTOMER_TIER, FIRST_CLOSED_WON_DATE
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT
WHERE LOWER(NAME) LIKE '%{{ customer | lower }}%'
AND ACCOUNT_STATUS = 'Customer'
LIMIT 5
```

If multiple matches, ask the user to pick one.

2. **Get MRR history (last 24 months, sampled monthly):**
```sql
SELECT DATE, ACCOUNT_FAMILY_MRR
FROM REPORTING.GENERAL.FACT_SALESFORCE_ACCOUNT_HISTORY
WHERE ID = '<sfdc_id>'
AND DATE >= DATEADD(MONTH, -24, CURRENT_DATE())
AND DAY(DATE) = 1
ORDER BY DATE
```

3. **Present the MRR report:**

### Current State
- Current MRR and customer tier
- Customer since date

### Month-by-Month MRR
- Display as a table: Month | MRR | MoM Change | MoM %
- Use a simple ASCII trend indicator (↑ ↓ →) for each month

### Key Metrics
- MRR 12 months ago vs today (YoY growth %)
- MRR 24 months ago vs today (2-year growth %)
- Highest MRR and when it occurred
- Lowest MRR (in the period) and when
- Average monthly change

### Notable Events
- Flag any month with >5% MoM change (up or down)
- Identify patterns (e.g., consistent growth, plateau, recent decline)

### Summary
- One-paragraph narrative of the MRR story for this account
- Is this account growing, stable, or contracting?
