#!/bin/bash
# Uninstaller for claude-code-realline
set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_PATH="$CLAUDE_DIR/statusline.sh"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

echo "==> Removing statusLine entry from settings.json..."
if [ -f "$SETTINGS_PATH" ]; then
  TMP_FILE=$(mktemp)
  jq 'del(.statusLine)' "$SETTINGS_PATH" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_PATH"
  echo "    Removed."
else
  echo "    No settings.json found, nothing to do."
fi

echo "==> Removing statusline.sh..."
if [ -f "$SCRIPT_PATH" ]; then
  rm "$SCRIPT_PATH"
  echo "    Removed."
else
  echo "    Not found, nothing to do."
fi

echo "==> Clearing weather cache..."
rm -f /tmp/claude_statusline_weather.cache

echo ""
echo "Done. Restart Claude Code — the statusline is gone, everything else in ~/.claude is untouched."
