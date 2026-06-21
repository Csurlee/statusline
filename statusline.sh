#!/bin/bash
# Claude Code statusline — real data only, no fake telemetry.
# Reads session JSON from stdin (Claude Code provides this automatically).

input=$(cat)

# Real ANSI escape bytes (ANSI-C quoting — not printf-dependent)
RED=$'\033[01;31m'
YELLOW=$'\033[01;33m'
GREEN=$'\033[01;32m'
RESET=$'\033[00m'

color_for_pct() {
  local p="${1%.*}"
  if   [ "$p" -ge 75 ]; then echo "$RED"
  elif [ "$p" -ge 50 ]; then echo "$YELLOW"
  else                        echo "$GREEN"
  fi
}

# ---- From Claude Code's JSON (always real, always current) ----
MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

DIR_SHORT="${DIR/#$HOME/~}"

# ---- Claude Code version (separate process call, cheap) ----
CC_VER=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[ -z "$CC_VER" ] && CC_VER="?"

# ---- Context bar ----
BAR_WIDTH=30
FILLED=$(( PCT * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
BAR=$(printf '%0.s#' $(seq 1 $FILLED) 2>/dev/null)
BAR+=$(printf '%0.s-' $(seq 1 $EMPTY) 2>/dev/null)
PCT_COLOR=$(color_for_pct "$PCT")

# ---- Rate limit usage (native field — Claude Code passes this directly, no API call) ----
FIVE_H_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_H_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

fmt_reset() {
  # Unix timestamp -> human readable, relative if today
  local ts="$1"
  [ -z "$ts" ] && return
  local now=$(date +%s)
  local diff=$(( ts - now ))
  if [ "$diff" -lt 86400 ] && [ "$diff" -ge 0 ]; then
    date -d "@$ts" +"%H:%M" 2>/dev/null || date -r "$ts" +"%H:%M" 2>/dev/null
  else
    date -d "@$ts" +"%a %H:%M" 2>/dev/null || date -r "$ts" +"%a %H:%M" 2>/dev/null
  fi
}

USE_LINE=""
if [ -n "$FIVE_H_PCT" ]; then
  P=${FIVE_H_PCT%.*}
  C=$(color_for_pct "$P")
  R=$(fmt_reset "$FIVE_H_RESET")
  USE_LINE+="5h: ${C}${P}%${RESET}"
  [ -n "$R" ] && USE_LINE+=" (resets ${R})"
fi
if [ -n "$WEEK_PCT" ]; then
  P=${WEEK_PCT%.*}
  C=$(color_for_pct "$P")
  R=$(fmt_reset "$WEEK_RESET")
  [ -n "$USE_LINE" ] && USE_LINE+=" | "
  USE_LINE+="Week: ${C}${P}%${RESET}"
  [ -n "$R" ] && USE_LINE+=" (resets ${R})"
fi

# ---- Git info (real, free) ----
cd "$DIR" 2>/dev/null
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  FIRST_COMMIT_TS=$(git log --reverse --format=%ct 2>/dev/null | head -1)
  if [ -n "$FIRST_COMMIT_TS" ]; then
    NOW_TS=$(date +%s)
    AGE_H=$(( (NOW_TS - FIRST_COMMIT_TS) / 3600 ))
    AGE="${AGE_H}h"
  else
    AGE="?"
  fi
  STASH=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
fi

# ---- Weather (cached 30min, no API key — Open-Meteo) ----
CACHE_FILE="/tmp/claude_statusline_weather.cache"
CACHE_TTL=1800
LAT="${STATUSLINE_LAT:-48.97}"   # default: Bietigheim-Bissingen area
LON="${STATUSLINE_LON:-9.13}"

WEATHER=""
if [ -f "$CACHE_FILE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE") ))
  if [ "$CACHE_AGE" -lt "$CACHE_TTL" ]; then
    WEATHER=$(cat "$CACHE_FILE")
  fi
fi
if [ -z "$WEATHER" ]; then
  RESP=$(curl -s --max-time 2 "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m" 2>/dev/null)
  TEMP=$(echo "$RESP" | jq -r '.current.temperature_2m // empty' 2>/dev/null)
  if [ -n "$TEMP" ]; then
    WEATHER="${TEMP}°C"
    echo "$WEATHER" > "$CACHE_FILE"
  fi
fi

TIME=$(date +%H:%M)

# ---- Render ----
LINE1="🕐 ${TIME}"
[ -n "$WEATHER" ] && LINE1+=" | ${WEATHER}"
LINE1+=" | CC:${CC_VER} | ${MODEL}"

LINE2="${PCT_COLOR}${BAR}${RESET} ${PCT}%"

LINE3="📁 ${DIR_SHORT}"
[ -n "$BRANCH" ] && LINE3+=" | Branch: ${BRANCH} | Age: ${AGE} | Stash: ${STASH}"
LINE3+=" | \$$(printf '%.2f' "$COST")"

OUT="$LINE1
$LINE2
$LINE3"
[ -n "$USE_LINE" ] && OUT+="
$USE_LINE"

printf "%s" "$OUT"
