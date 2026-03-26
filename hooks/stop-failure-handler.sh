#!/bin/bash
# Super Hype Harness - StopFailure Hook
# Detects rate_limit errors and schedules automatic resume
#
# Install: Add to Claude Code settings.json:
# "hooks": {
#   "StopFailure": [{
#     "matcher": "",
#     "hooks": [{ "type": "command", "command": "bash hooks/stop-failure-handler.sh" }]
#   }]
# }

set -euo pipefail

INPUT=$(cat)
ERROR=$(echo "$INPUT" | jq -r '.error // empty')

# Only handle rate_limit errors
if [ "$ERROR" != "rate_limit" ]; then
  exit 0
fi

HARNESS_DIR="docs/harness"
STATE_FILE="$HARNESS_DIR/state.md"
CONFIG_FILE="$HARNESS_DIR/config.md"

# Check if harness is running
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

STATUS=$(grep "^- status:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/.*: //' || echo "")
if [ "$STATUS" != "running" ]; then
  exit 0
fi

# Check auto_resume setting (covers both config and --no-auto-resume flag)
if [ -f "$CONFIG_FILE" ]; then
  AUTO_RESUME=$(grep "^auto_resume:" "$CONFIG_FILE" | awk '{print $2}')
  if [ "$AUTO_RESUME" = "false" ]; then
    # Pause but don't schedule resume
    sed -i '' 's/^- status: running/- status: paused/' "$STATE_FILE" 2>/dev/null || \
    sed -i 's/^- status: running/- status: paused/' "$STATE_FILE"
    osascript -e 'display notification "Harness paused (rate limit). Auto-resume disabled." with title "Super Hype Harness"' 2>/dev/null || true
    exit 0
  fi
fi

# Update state to paused
PAUSED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i '' "s/^- status: running/- status: paused/" "$STATE_FILE" 2>/dev/null || \
sed -i "s/^- status: running/- status: paused/" "$STATE_FILE"

# Try to parse resets_at from StatusLine JSON cache
STATUSLINE_CACHE="$HOME/.claude/statusline-cache.json"
RESETS_AT=""
if [ -f "$STATUSLINE_CACHE" ]; then
  RESETS_AT=$(jq -r '.rate_limits.five_hour.resets_at // empty' "$STATUSLINE_CACHE" 2>/dev/null || echo "")
fi

if [ -n "$RESETS_AT" ] && [ "$RESETS_AT" != "null" ] && [ "$RESETS_AT" != "" ]; then
  RESUME_EPOCH="$RESETS_AT"
else
  # Default: 5 hours from now
  RESUME_EPOCH=$(($(date +%s) + 18000))
fi

# Platform-compatible date formatting
if [[ "$OSTYPE" == "darwin"* ]]; then
  RESUME_AT=$(date -u -r "$RESUME_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")
  RESUME_TIME=$(date -r "$RESUME_EPOCH" +"%H:%M %m/%d/%Y")
else
  RESUME_AT=$(date -u -d "@$RESUME_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")
  RESUME_TIME=$(date -d "@$RESUME_EPOCH" +"%H:%M %m/%d/%Y")
fi

# Initialize resume_attempts if not present
if ! grep -q "^- resume_attempts:" "$STATE_FILE" 2>/dev/null; then
  echo "- resume_attempts: 0" >> "$STATE_FILE"
fi

# Schedule resume via at command
echo "claude -p '/harness --resume'" | at "$RESUME_TIME" 2>/dev/null || true

# Notify user
osascript -e "display notification \"Harness paused (rate limit). Auto-resume at $RESUME_AT\" with title \"Super Hype Harness\"" 2>/dev/null || true
