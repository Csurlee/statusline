# claude-code-realline

A Claude Code statusline that shows only real data — no fake telemetry, no placeholder numbers, no fields that need an entire framework running underneath them to mean anything.

```
🕐 14:11 | 18.2°C | CC:2.1.92 | sonnet-4-6
████████████████████████------ 75%
📁 ~/pfsense-soc | Branch: main | Age: 4h | Stash: 1 | $4.81
5h: 40% (resets 16:11) | Week: 99% (resets Wed 14:11)
```

## What it shows

| Field | Source | Always available? |
|---|---|---|
| Time | local system clock | yes |
| Weather | [Open-Meteo](https://open-meteo.com) (free, no API key) | yes, if network allows |
| Claude Code version | `claude --version` | yes |
| Model name | Claude Code session JSON | yes |
| Context window % | Claude Code session JSON | yes |
| Working directory, git branch, repo age, stash count | local `git` | yes, if in a git repo |
| Session cost | Claude Code session JSON | yes |
| 5-hour rate limit % + reset time | Claude Code session JSON (`rate_limits` field) | **only** on Claude Code ≥ v2.1.80 with Pro/Max subscription auth |
| Weekly rate limit % + reset time | same as above | same as above |

Every field is something Claude Code or a free public API actually reports. Nothing here is computed from a tracking system you don't have running.

## What it does **not** show, and why

If you've seen other "AI statusline" projects with skill counts, hook counts, memory entry counts, or learning sparklines — those numbers only mean something if a hook system is logging every event to a database in the background. Bolting fake versions of those fields onto a script and showing zeros (or worse, hardcoded numbers) is decoration, not data. This project deliberately doesn't include them. 

## Requirements

- Claude Code installed
- `jq`
- `curl`
- `git` (optional — branch/age/stash fields just stay blank without it)

**macOS:**
```bash
brew install jq
```

**Debian/Ubuntu:**
```bash
sudo apt install jq
```

**Fedora/RHEL:**
```bash
sudo dnf install jq
```

**Windows:** not natively supported. The script is bash; use WSL or Git Bash. No PowerShell port exists yet — contributions welcome.

## Install

### One-line install
```bash
curl -fsSL https://raw.githubusercontent.com/Csurlee/statusline/main/install.sh | bash
```
Piping a remote script into `bash` runs whatever the server returns. If you'd rather inspect first:
```bash
curl -fsSL https://raw.githubusercontent.com/Csurlee/statusline/main/install.sh -o install.sh
less install.sh
bash install.sh
```

### Manual install
```bash
mkdir -p ~/.claude
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/Csurlee/statusline/main/statusline.sh
chmod +x ~/.claude/statusline.sh
```
Then add this to `~/.claude/settings.json` (merge it in if the file already has other keys — don't overwrite):
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```
Validate the JSON before restarting:
```bash
jq . ~/.claude/settings.json
```

Restart Claude Code. The statusline won't appear until you do.

## Configuration

Weather defaults to a placeholder location. Set your own coordinates as environment variables (add to `~/.zshrc` or `~/.bashrc` to persist):
```bash
export STATUSLINE_LAT="48.97"
export STATUSLINE_LON="9.13"
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Csurlee/statusline/main/uninstall.sh | bash
```
This only removes the `statusLine` key from `settings.json` and deletes `statusline.sh` — it does not touch anything else in `~/.claude`.

## Troubleshooting

**Statusline doesn't appear at all**
- Missing execute permission: `chmod +x ~/.claude/statusline.sh`
- Workspace trust not accepted — Claude Code won't run shell commands in an untrusted workspace
- Invalid JSON in `settings.json` — run `jq . ~/.claude/settings.json` to check

**5h / Week lines never show up**
- Requires Claude Code ≥ v2.1.80 — check with `claude --version`
- Requires Pro/Max subscription auth — API-key billing doesn't have these windows
- If both are true and it's still missing, the field may have moved; open an issue with your `claude --version` output

**Weather is wrong or missing**
- Set `STATUSLINE_LAT` / `STATUSLINE_LON` (see Configuration above)
- Network may be blocking outbound requests to `api.open-meteo.com`
- Cached for 30 minutes — won't update faster than that by design

## Artifact

```
https://claude.site/public/artifacts/12ad11dd-e377-4bbf-8113-596c6d477eb0/embed
```

## License

MIT — see [LICENSE](LICENSE).
