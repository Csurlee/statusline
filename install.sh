#!/bin/bash
# Installer for claude-code-realline (real-data-only statusline)
set -e

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main}"
CLAUDE_DIR="$HOME/.claude"
SCRIPT_PATH="$CLAUDE_DIR/statusline.sh"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"

echo "==> Checking dependencies..."

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not installed."
  echo "  macOS:         brew install jq"
  echo "  Debian/Ubuntu: sudo apt install jq"
  echo "  Fedora/RHEL:   sudo dnf install jq"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required but not installed."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "WARNING: git not found. Branch/age/stash fields in the statusline will be blank."
fi

echo "==> Creating $CLAUDE_DIR if needed..."
mkdir -p "$CLAUDE_DIR"

echo "==> Downloading statusline.sh..."
curl -fsSL "$REPO_RAW_URL/statusline.sh" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

echo "==> Configuring settings.json..."
if [ -f "$SETTINGS_PATH" ]; then
  # Merge into existing settings.json without clobbering other keys
  TMP_FILE=$(mktemp)
  jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh"}' \
    "$SETTINGS_PATH" > "$TMP_FILE" && mv "$TMP_FILE" "$SETTINGS_PATH"
else
  cat > "$SETTINGS_PATH" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
EOF
fi

echo "==> Validating settings.json..."
jq . "$SETTINGS_PATH" > /dev/null

echo ""
echo "Done. Restart Claude Code to see the statusline."
echo ""
echo "Optional: set your coordinates for accurate weather (defaults to a generic location):"
echo "  export STATUSLINE_LAT=\"YOUR_LATITUDE\""
echo "  export STATUSLINE_LON=\"YOUR_LONGITUDE\""
echo "Add those lines to your ~/.zshrc or ~/.bashrc to make them permanent."
