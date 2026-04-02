#!/bin/bash
set -e

# Install uv if not present
if ! command -v uvx &> /dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Create Snowflake config directory
CONFIG_DIR="$HOME/.config/mcp"
CONFIG_FILE="$CONFIG_DIR/snowflake-config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$CONFIG_DIR"

  SNOWFLAKE_USER="$(whoami)@datadoghq.com"

  cat > "$CONFIG_FILE" <<EOF
connection:
  account: sza96462.us-east-1
  user: ${SNOWFLAKE_USER}
  authenticator: externalbrowser
  database: REPORTING

permissions:
  SELECT: true
  DESCRIBE: true
  USE: true
  COMMAND: true
  ALTER: false
  CREATE: false
  DELETE: false
  DROP: false
  INSERT: false
  UPDATE: false
  TRUNCATE: false
  GRANT: false
  REVOKE: false
EOF

  echo "Snowflake config created at $CONFIG_FILE for user $SNOWFLAKE_USER"
fi
