#!/usr/bin/env zsh

# Arch Update Readiness Checker
# Checks Arch News, system status, and AUR updates safely before updating

set -euo pipefail

NEWS_URL="https://archlinux.org/news/"
TMP_NEWS="/tmp/arch_news.html"
TMP_WARNINGS="/tmp/arch_news_warnings.txt"

FORCE=false
RUN_UPDATE=false
QUIET=false

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
RESET="\e[0m"

log() {
  $QUIET || echo -e "$1"
}

usage() {
  echo "Usage: arch-update-check [--update] [--force] [--quiet]"
  exit 1
}

for arg in "$@"; do
  case $arg in
    --update) RUN_UPDATE=true ;;
    --force) FORCE=true ;;
    --quiet) QUIET=true ;;
    *) usage ;;
  esac
 done

### Fetch Arch News ###
log "Fetching Arch Linux news (fast-fail)..."
if ! curl -4 -fsSL --connect-timeout 3 --max-time 5 --retry 0 "$NEWS_URL" -o "$TMP_NEWS"; then
  log "${YELLOW}Skipping Arch News check (network timeout).${RESET}"
  WARN_COUNT=0
  : > "$TMP_WARNINGS"
else
  ( grep -iE "manual intervention|requires manual|breaking|important" "$TMP_NEWS" || true ) \
    | sed -E 's/<[^>]+>//g' \
    | sed -E 's/&gt;=/>=/g' \
    | sed -E 's/&amp;/\&/g' \
    | awk '{$1=$1;print}' \
    | head -n 10 > "$TMP_WARNINGS"
  WARN_COUNT=$(wc -l < "$TMP_WARNINGS")
fi

### Installed packages mentioned in news ###
AFFECTED_PKGS=()
if [[ $WARN_COUNT -gt 0 ]]; then
  while read -r line; do
    for pkg in $(pacman -Qq); do
      if echo "$line" | grep -qi "$pkg"; then
        AFFECTED_PKGS+=("$pkg")
      fi
    done
  done < "$TMP_WARNINGS"
fi

### System checks ###
FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
PARTIAL_UPGRADE=false
if pacman -Qu | grep -q .; then
  PARTIAL_UPGRADE=false
else
  PARTIAL_UPGRADE=true
fi

### yay / AUR checks ###
YAY_AVAILABLE=false
AUR_UPDATES=0
FAILED_AUR_BUILDS=0

if command -v yay >/dev/null 2>&1; then
  YAY_AVAILABLE=true
  log "Checking AUR updates (timeout 20s)..."

  if pgrep -x yay >/dev/null; then
    log "${YELLOW}Another yay process detected. Skipping AUR checks.${RESET}"
    AUR_UPDATES=0
  else
    AUR_UPDATES=$((timeout 20 yay -Qua --noconfirm --nodiffmenu --noeditmenu 2>/dev/null || true) | wc -l)
  fi

  FAILED_AUR_BUILDS=$(find ~/.cache/yay -mindepth 1 -maxdepth 1 -type d | wc -l)
  log "AUR check completed."
fi

### Report ###
log "\n⚠ Arch Update Readiness Report"

if [[ $WARN_COUNT -gt 0 ]]; then
  log "${YELLOW}Arch News Alerts:${RESET}"
  cat "$TMP_WARNINGS"
else
  log "${GREEN}No critical Arch News alerts detected.${RESET}"
fi

log "\nSystem Checks:"
log "- Failed systemd services: $FAILED_SERVICES"
log "- Partial upgrade detected: $PARTIAL_UPGRADE"

if $YAY_AVAILABLE; then
  log "\nAUR Checks:"
  log "- Pending AUR updates: $AUR_UPDATES"
  log "- Cached build directories: $FAILED_AUR_BUILDS"
else
  log "\n${YELLOW}yay not detected. Skipping AUR checks.${RESET}"
fi

if [[ ${#AFFECTED_PKGS[@]} -gt 0 ]]; then
  log "\nInstalled packages mentioned in warnings:"
  printf '%s
' "${AFFECTED_PKGS[@]}" | sort -u
fi

### Decision logic ###
EXIT_CODE=0
RECOMMENDATION="Safe to update"

if [[ $WARN_COUNT -gt 0 ]]; then
  EXIT_CODE=1
  RECOMMENDATION="Update requires attention"
fi

if [[ $PARTIAL_UPGRADE == true || $FAILED_SERVICES -gt 0 || ${#AFFECTED_PKGS[@]} -gt 0 ]]; then
  EXIT_CODE=2
  RECOMMENDATION="DO NOT UPDATE"
fi

log ""
case $EXIT_CODE in
  0) log "${GREEN}Recommendation: $RECOMMENDATION${RESET}" ;;
  1) log "${YELLOW}Recommendation: $RECOMMENDATION${RESET}" ;;
  2) log "${RED}Recommendation: $RECOMMENDATION${RESET}" ;;
esac

### Run updates ###
if $RUN_UPDATE; then
  if [[ $EXIT_CODE -eq 0 || $FORCE == true ]]; then
    log "\nUpdating official repositories..."
    sudo pacman -Syu

    if $YAY_AVAILABLE; then
      log "\nUpdating AUR packages..."
      yay -Sua --noconfirm --nodiffmenu --noeditmenu
    fi
  else
    log "\n${RED}Update blocked. Use --force if you enjoy consequences.${RESET}"
  fi
fi

log "Reached end of script"
exit $EXIT_CODE
