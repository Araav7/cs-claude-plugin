# CS Claude Plugin

## What This Is
A Claude Code plugin for Customer Success managers at Datadog. It auto-configures MCP servers (Snowflake, Atlassian) and provides skills for account analysis — no technical knowledge required.

## Target Users
- Customer Success Managers (non-technical)
- Only prerequisite: Claude Code installed
- Plugin handles everything else (uv install, Snowflake config, MCP setup)

## Plugin Architecture

### File Structure
```
cs-claude-plugin/
├── .claude-plugin/
│   └── plugin.json          # Manifest (name, version, userConfig)
├── commands/                 # Slash command skills
│   ├── account-health.md    # /account-health <customer>
│   ├── renewal-prep.md      # /renewal-prep <customer>
│   ├── adoption.md          # /adoption <customer>
│   ├── power-users.md       # /power-users <customer>
│   ├── churn-risk.md        # /churn-risk <customer>
│   ├── mrr-trend.md         # /mrr-trend <customer>
│   ├── expansion.md         # /expansion <customer>
│   └── my-portfolio.md      # /my-portfolio
├── .mcp.json                # Snowflake + Atlassian MCP configs
├── hooks/
│   └── hooks.json           # SessionStart hook for auto-setup
├── scripts/
│   └── setup.sh             # Installs uv, creates Snowflake config YAML
└── README.md
```

### MCP Servers to Configure
1. **Snowflake** (stdio) — account data, MRR, adoption, contracts
2. **Atlassian** (HTTP/OAuth) — Confluence wiki access
3. **Slack** (built-in plugin) — enabled via settings.json

### SessionStart Hook
- Checks if `uvx` is installed, installs `uv` if missing
- Creates `~/.config/mcp/snowflake-config.yaml` if missing (read-only SQL permissions)

### userConfig
- No user input required — Snowflake username is derived automatically via `$(whoami)@datadoghq.com`

## Snowflake Data Available

### Database: REPORTING

#### Schema: GENERAL

**DIM_SALESFORCE_ACCOUNT** — Account lookup
- Search: `LOWER(NAME) LIKE '%keyword%'`
- Key columns: ID, NAME, ORG_ID, SALES_SEGMENT, WORLD_REGION, EMPLOYEE_COUNT, INDUSTRY, PRODUCT_LIST, COMPETITORS, ACCOUNT_STATUS, ACCOUNT_HEALTH_STATUS, HEALTH_STATUS_DETAILS, HEALTH_STATUS_DETAILS_HISTORY, ACCOUNT_PRIORITIZATION, ACCOUNT_FAMILY_MRR, CUSTOMER_TIER, FIRST_CLOSED_WON_DATE, CHURN_RISK_LIKELIHOOD, CHURN_RISK_REASON, HAS_EB_CHAMPION_ISSUES, HAS_USAGE_CONTRACT_ISSUES, HAS_COMMUNICATION_QUALITY_ISSUES
- Note: Column is `NAME` not `ACCOUNT_NAME`, `ID` not `ACCOUNT_ID`

**ACCOUNT_PROFILE** — Simplified account view
- Key columns: ORG_ID, ORG_NAME, COUNT_USERS, BILLING_PLAN_CURRENT, CUSTOMER_TIER, ACCOUNT_OWNER_NAME, ACCOUNT_OWNER_EMAIL, SALES_ENGINEER_NAME, ACCOUNT_STATUS, ACCOUNT_HEALTH_STATUS, CREATION_YEAR, DAY_SINCE_CREATION

**FACT_SALESFORCE_ACCOUNT_HISTORY** — MRR history
- Filter: `ID = '<sfdc_account_id>'` and date range
- Key column: `ACCOUNT_FAMILY_MRR` (daily granularity)
- Tip: Sample monthly (first of each month) to avoid huge result sets

**FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY** — Product adoption
- Filter: `ORG_ID = <org_id>`
- Key columns: PAGEVIEW_TIMESTAMP, ORG_ID, DATADOG_USER_ID, PRODUCT_GROUP, INTERACTIONS_COUNT, TIME_SPENT_ON_PAGE_SECONDS
- Aggregate by PRODUCT_GROUP for adoption overview, by DATADOG_USER_ID for power users

#### Schema: GTM

**FACT_SFDC_OPPORTUNITY_RESTRICTED_HISTORY** — Opportunities
- Filter: `ACCOUNT_ID = '<sfdc_account_id>' AND IS_MOST_RECENT_DATE = TRUE`
- Key columns: OPPORTUNITY_ID, OPPORTUNITY_NAME, TYPE, STAGE, CLOSE_DATE, NEXT_STEP

**FACT_SFDC_CONTRACT_RESTRICTED_HISTORY** — Contracts
- Filter: `ACCOUNT_ID = '<sfdc_account_id>' AND IS_MOST_RECENT_DATE = TRUE`
- Key columns: CONTRACT_ID, CONTRACT_NAME, STATUS, PLAN_TYPE, START_DATE, END_DATE, YEAR_1_CONTRACT_FEE, DRAWDOWN_REMAINING_BALANCE

### Optimal Query Strategy
1. Find account in `GENERAL.DIM_SALESFORCE_ACCOUNT` by name → get ID and ORG_ID
2. In parallel: ACCOUNT_PROFILE, MRR history, adoption pageviews, GTM opportunities, GTM contracts
3. Deep-dive on users from step 2

## Skills to Build

| Skill | Purpose | Key Tables |
|-------|---------|------------|
| `/account-health` | Full account briefing — health, MRR, tier, churn risk, flags | DIM_SALESFORCE_ACCOUNT, ACCOUNT_PROFILE |
| `/renewal-prep` | Renewal prep — contracts, MRR trend, adoption, opportunities | All tables |
| `/adoption` | Product adoption — which products used, unused, by whom | FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY |
| `/power-users` | Top users by activity, products they use, time spent | FACT_APP_PAGEVIEW_BY_PRODUCT_GROUP_HISTORY |
| `/churn-risk` | Churn analysis — risk score, reasons, trend correlation | DIM_SALESFORCE_ACCOUNT, MRR history, adoption |
| `/mrr-trend` | MRR over 12-24 months, month by month | FACT_SALESFORCE_ACCOUNT_HISTORY |
| `/expansion` | Upsell/cross-sell opportunities — paid vs used vs unused | DIM_SALESFORCE_ACCOUNT (PRODUCT_LIST), adoption |
| `/my-portfolio` | All accounts for current user, sorted by health/renewal | DIM_SALESFORCE_ACCOUNT, contracts |

## Snowflake Connection Details
- Account: `sza96462.us-east-1`
- Database: `REPORTING`
- Auth: `externalbrowser` (browser-based SSO)
- User: `<username>@datadoghq.com`

## Snowflake Config YAML (read-only permissions)
Written to `~/.config/mcp/snowflake-config.yaml`:
- SELECT: true
- DESCRIBE: true
- USE: true
- COMMAND: true
- Everything else (ALTER, CREATE, DELETE, DROP, INSERT, UPDATE, etc.): false

## Design Principles
- Everything should "just work" after `/plugin install`
- No terminal commands required from the user
- Skills should accept a customer name and handle the full lookup flow
- Always start by finding the account in DIM_SALESFORCE_ACCOUNT to get ID and ORG_ID before querying other tables
