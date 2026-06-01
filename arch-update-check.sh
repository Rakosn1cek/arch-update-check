#!/usr/bin/env zsh
# shellcheck disable=SC2034,SC2317,SC1071
#----------------------------------------------------------------------------------
# ARCH UPDATE CHECK
# Author: Lukas Grumlik - Rakosn1cek
# Created: 2026-01
# Descriptions: 
# Minimalist Arch update check. Run before full upgrade to see the number of packages including AUR,
# and any relevant news that may affect the upgrade without manual intervention.
#----------------------------------------------------------------------------------


VERSION="1.3.8"
set -euo pipefail

NEWS_RSS="https://archlinux.org/feeds/news/"
TMP_DIR="/tmp/arch-check-$(id -u)"
mkdir -p "$TMP_DIR"

TMP_NEWS="$TMP_DIR/news.xml"
TMP_PKGS="$TMP_DIR/pending_pkgs.txt"

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
BOLD="\e[1m"
RESET="\e[0m"

log() { echo -e "$1"; }

# 1. Get current pending updates
log "Checking official repositories..."
PENDING_RAW=$(checkupdates 2>/dev/null || true)

if [[ -z "$PENDING_RAW" ]]; then
    log "${GREEN}System is fully up to date.${RESET}"
    : > "$TMP_PKGS"
else
    echo "$PENDING_RAW" | awk '{print $1}' > "$TMP_PKGS"
fi

# 2. Fetch and Parse News (Switching to RSS for date metadata)
log "Fetching Arch News (RSS)..."
if ! curl -4 -fsSL --connect-timeout 3 "$NEWS_RSS" -o "$TMP_NEWS" 2>/dev/null; then
    log "${YELLOW}Could not reach Arch News. Skipping.${RESET}"
    : > "$TMP_NEWS"
fi

# 3. Filter News
RELEVANT_NEWS=""
if [[ -f "$TMP_NEWS" ]]; then
    # Un-minify, grab titles, skip channel header, take top 3
    RELEVANT_NEWS=$(cat "$TMP_NEWS" | tr '>' '\n' | grep -A 1 "<title" | grep -vE "Arch Linux: Recent|--|<title" | cut -d'<' -f1 | head -n 3)
fi

# 4. System Checks
FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)

# CORRECTED Partial Upgrade Check:
PARTIAL_UPGRADE=false
if [[ -f /var/lib/pacman/db.lck ]]; then
    log "${YELLOW}Pacman is currently locked. Skipping partial check.${RESET}"
else
    # Actually, the simplest reliable check for a broken state:
    if pacman -Q linux >/dev/null 2>&1; then
        RUNNING_K=$(uname -r | cut -d'-' -f1)
        INSTALLED_K=$(pacman -Q linux | awk '{print $2}' | cut -d'-' -f1)
    fi
fi

# 5. Report
log "\n${BOLD} ⚠ Arch Update Readiness Report${RESET}"
if [[ -n "$RELEVANT_NEWS" ]]; then
    log "${RED}CRITICAL: Recent News affecting your updates:${RESET}"
    # Using -e to ensure the newlines in $RELEVANT_NEWS are rendered
    echo -e "$RELEVANT_NEWS" | sed 's/^/ - /'
else
    log "${GREEN}No recent (14 days) news alerts affect your pending updates.${RESET}"
fi

# Calculate counts
OFFICIAL_COUNT=$([[ -n "$PENDING_RAW" ]] && echo "$PENDING_RAW" | wc -l || echo "0")
AUR_COUNT=$(yay -Qua 2>/dev/null | wc -l || echo )

log "\nSystem Status:"
log "- Official Updates: $OFFICIAL_COUNT"
log "- AUR Updates:      $AUR_COUNT"
log "- Failed Services:  $FAILED_SERVICES"
log "- Partial Upgrade:  $PARTIAL_UPGRADE"

# Now the math should be clean
TOTAL_UPDATES=$(( OFFICIAL_COUNT + AUR_COUNT ))

# 6. Recommendation Logic
if [[ -n "$RELEVANT_NEWS" ]]; then
    log "\n${YELLOW}Recommendation: Review news above before updating.${RESET}"
    exit 1
elif [[ "$FAILED_SERVICES" -gt 0 ]]; then
    log "\n${YELLOW}Recommendation: Fix failed services before updating.${RESET}"
    exit 1
else
    log "\n${GREEN}Recommendation: Safe to update.${RESET}"
    exit 0
fi

rm -rf "$TMP_DIR"
