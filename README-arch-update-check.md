# Arch Update Readiness Checker

Because blindly running `pacman -Syu` on Arch Linux is a lifestyle choice, not a requirement.

This script checks whether updating your system *right now* is sensible or likely to result in an evening spent reinstalling packages, reading Arch News you skipped, and questioning your decisions.

---

## What This Script Does

Before any system update, the script:

* Fetches the latest **Arch Linux News**
* Scans for:

  * Breaking changes
  * Manual intervention notices
  * Package renames or removals
* Compares warnings against your **installed packages**
* Checks for common update hazards:

  * Partial upgrades
  * Held packages
  * Failed systemd services

Then it delivers a clear verdict instead of false optimism.

---

## Example Output

```
⚠ Arch Update Readiness Report

Arch News Alerts:
- Manual intervention required: glibc update
- Affected packages detected: steam, wine

System Checks:
- Partial upgrade: none detected
- Failed services: 0

Recommendation: DO NOT UPDATE
Reason: Manual intervention required
```

If everything is fine, the script will say so without drama.

---

## Features

* Color-coded terminal output
* Human-readable warnings
* Optional prompt before running `pacman -Syu`
* Logs update checks for future reference
* Designed to be fast and dependency-light

---

## Requirements

* Arch Linux (obviously)
* `curl`
* `grep`, `awk`, `sed`
* `pacman`
* Internet connection (news does not read itself)

---

## Installation

Clone the repository:

```
git clone https://github.com/Rakosn1cek/arch-update-check.git
cd arch-update-check
```

Make the script executable:

```
chmod +x arch-update-check.sh
```

Optional: move it into your PATH

```
sudo mv arch-update-check.sh /usr/local/bin/arch-update-check
```

---

## Usage

Run manually before updating:

```
arch-update-check
```

Or use it as a pacman wrapper:

```
arch-update-check --update
```

Available flags:

* `--update`  Runs `pacman -Syu` only if checks pass
* `--force`   Runs update anyway (no judgment, just logging)
* `--quiet`   Minimal output

---

## Exit Codes

* `0` Safe to update
* `1` Warnings detected
* `2` Update strongly discouraged

Useful for scripting and automation.

---

## Why This Exists

Created this script for myself. As a noob in Arch Linux I make mistakes, but I don't realy want to spent hours fixing my already done hard work.

Arch Linux expects you to read the news.

This script assumes you are human and occasionally forget, get distracted, or trust your memory too much. It automates the boring part so you can focus on not breaking your system.

---

## Disclaimer

This script reduces risk. It does not eliminate it.

If you ignore warnings, use `--force`, and update anyway, the consequences are between you and your backup strategy.

---

## License

MIT License. Break your system freely.
