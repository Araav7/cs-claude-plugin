# CS Claude Plugin

Account intelligence for Customer Success managers at Datadog. Query account health, MRR trends, product adoption, churn risk, and more — all from Claude Code using simple slash commands.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

That's it. The plugin handles everything else automatically.

## Installation

Open Claude Code and run these three commands:

**1. Add the plugin marketplace:**
```
/plugin marketplace add Araav7/cs-claude-plugin
```

**2. Install the plugin:**
```
/plugin install cs-plugin@cs-claude-plugin
```

**3. Reload plugins:**
```
/reload-plugins
```

On first session, the plugin will automatically:
- Install [uv](https://github.com/astral-sh/uv) (Python package manager) if not present
- Create your Snowflake config at `~/.config/mcp/snowflake-config.yaml` using your system username
- Connect to the Snowflake and Atlassian MCP servers

The first time a Snowflake query runs, a browser window will open for SSO authentication. Click through to authorize — this is a one-time step.

## Commands

### `/account-health <customer>`

Full account briefing: health status, MRR, customer tier, churn risk, risk flags, team contacts, and competitive context.

```
/account-health Acme Corp
```

---

### `/renewal-prep <customer>`

Renewal preparation brief: active contracts with end dates, 12-month MRR trend, product adoption vs. contract coverage, open opportunities, and risk/leverage points.

```
/renewal-prep Acme Corp
```

---

### `/adoption <customer>`

Product adoption breakdown: which products are actively used, weekly engagement trends, paid-but-unused products (risk), and used-but-unpaid products (expansion opportunity).

```
/adoption Acme Corp
```

---

### `/power-users <customer>`

Top 20 users ranked by engagement: products each user touches, hours spent, last active date. Identifies product champions and flags users who have gone quiet.

```
/power-users Acme Corp
```

---

### `/churn-risk <customer>`

Churn risk assessment: risk score, contributing signals (champion loss, usage decline, communication issues), MRR and engagement trajectories, contract exposure, and a prioritized action plan.

```
/churn-risk Acme Corp
```

---

### `/mrr-trend <customer>`

24-month MRR history: month-by-month table with MoM changes, YoY growth, peak/trough analysis, and a narrative summary of the account's revenue trajectory.

```
/mrr-trend Acme Corp
```

---

### `/expansion <customer>`

Expansion opportunity analysis: cross-sell candidates (products used but not contracted), upsell signals (heavy usage on current products), underutilized products needing enablement, and prioritized recommended plays.

```
/expansion Acme Corp
```

---

### `/my-portfolio`

Full portfolio view for your accounts: total MRR, accounts by health status, upcoming renewals in the next 90 days, risk-flagged accounts, and a recommended focus list. No arguments needed — it detects your accounts automatically.

```
/my-portfolio
```

## Troubleshooting

**"No matches found" when searching for an account**
- Try a shorter or different variation of the name (e.g., "Acme" instead of "Acme Corporation")
- The search uses fuzzy matching (`LIKE '%keyword%'`) so partial names work

**Snowflake authentication error**
- A browser window should open for SSO. If it doesn't, check that your system username matches your Datadog email prefix
- Verify your config: `cat ~/.config/mcp/snowflake-config.yaml`
- The `user` field should be `<your-username>@datadoghq.com`

**"uvx not found" error**
- The setup script should install it automatically. If it failed, install manually: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Then restart Claude Code

**MCP server not connecting**
- Restart Claude Code — the SessionStart hook runs on each new session
- Check that `~/.config/mcp/snowflake-config.yaml` exists and has the correct account/user

## Updating

The plugin updates automatically when you start a new Claude Code session. To force an update:

```
/plugin install cs-plugin@cs-claude-plugin
/reload-plugins
```
