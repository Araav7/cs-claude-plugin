---
description: View all accounts in your portfolio, sorted by health and upcoming renewals
---

You are helping a Customer Success manager review their full portfolio.

## Steps

1. **Determine the current user's email:**
Run a shell command to get the username:
```bash
whoami
```
Then construct the email: `<result>@datadoghq.com`

2. **Find all accounts owned by this user:**
```sql
SELECT a.ID, a.NAME, a.ORG_ID, a.ACCOUNT_FAMILY_MRR, a.CUSTOMER_TIER,
       a.ACCOUNT_HEALTH_STATUS, a.CHURN_RISK_LIKELIHOOD, a.CHURN_RISK_REASON,
       a.ACCOUNT_PRIORITIZATION, a.SALES_SEGMENT,
       a.HAS_EB_CHAMPION_ISSUES, a.HAS_USAGE_CONTRACT_ISSUES, a.HAS_COMMUNICATION_QUALITY_ISSUES
FROM REPORTING.GENERAL.DIM_SALESFORCE_ACCOUNT a
JOIN REPORTING.GENERAL.ACCOUNT_PROFILE p ON a.ORG_ID = p.ORG_ID
WHERE LOWER(p.ACCOUNT_OWNER_EMAIL) = '<user_email>'
AND a.ACCOUNT_STATUS = 'Customer'
ORDER BY a.ACCOUNT_FAMILY_MRR DESC
```

3. **Get upcoming renewals for these accounts:**
```sql
SELECT ACCOUNT_ID, CONTRACT_NAME, END_DATE, STATUS
FROM REPORTING.GTM.FACT_SFDC_CONTRACT_RESTRICTED_HISTORY
WHERE ACCOUNT_ID IN (<account_ids_from_step_2>)
AND IS_MOST_RECENT_DATE = TRUE
AND STATUS = 'Active'
AND END_DATE >= CURRENT_DATE()
ORDER BY END_DATE
```

4. **Present the portfolio view:**

### Portfolio Summary
- Total accounts
- Total MRR across portfolio
- Accounts by health status (count per status)
- Accounts by tier

### Accounts Needing Attention
- Accounts with poor health status or high churn risk — list first
- Accounts with any risk flags (champion, usage, communication issues)
- Sort by urgency

### Upcoming Renewals (next 90 days)
- Account name, renewal date, MRR, health status
- Days until renewal
- Flag any renewals where health is poor or churn risk is high

### Full Portfolio Table
| Account | MRR | Tier | Health | Churn Risk | Segment | Next Renewal |
Sort by MRR descending.

### Recommended Focus
- Top 3-5 accounts that need immediate attention and why
