# ARCH UPDATE CHECK
[v1.3.8]

Because blindly running `pacman -Syu` on Arch Linux is a lifestyle choice, not a requirement.

This script checks whether updating the system right now is sensible, or likely to result in an evening spent recovering broken packages, reading missed Arch News announcements, and questioning choices.

---

## What This Script Does

Before running a system update, the utility:

* Fetches the latest official **Arch Linux News** RSS feed.
* Extracts the top 3 recent headlines to catch critical manual intervention notices.
* Checks for common system update hazards:
    * Failed systemd services (`systemctl --failed`).
    * Active pacman database locks (`db.lck`).
* Calculates pending package counts across official repositories and the AUR.

It then delivers a direct visual verdict instead of false optimism.

---

## Example Output

```
 ⚠ Arch Update Readiness Report
CRITICAL: Recent News affecting your updates:
 - Breaking changes for all users of `varnish`, which is renamed to `vinyl-cache`
 - kea &gt;= 1:3.0.3-6 update requires manual intervention
 - iptables now defaults to the nft backend

System Status:
- Official Updates: 27
- AUR Updates:      0
- Failed Services:  0
- Partial Upgrade:  false

Recommendation: Review news above before updating.
```

If the system configuration is clean and no recent news flags are fetched, the tool reports back without drama.

---

## Features

* Clean terminal output.
* Lightweight and fast shell footprint.
* Failsafe integer validation for repository tracking.
* Zero external dependencies beyond standard system utilities.

---

## Requirements

* Arch Linux
* `curl`
* `awk`, `sed`, `grep`
* `pacman`
* `yay` (for tracking AUR statistics)

---

## Installation
**AUR**

`yay -S arch-update-check`

**Clone the repository**:

`git clone https://github.com/Rakosn1cek/arch-update-check.git`

`cd arch-update-check`

**Optional**: move it into your PATH

`sudo mv arch-update-check.sh /usr/local/bin/arch-update-check`

---

## Usage

Run manually before updating:

`arch-update-check`

---

## Exit Codes

* `0` Safe to update. No critical news alerts or failed services found.
* `1` Action required. Warnings detected or systemd services require attention.

Useful for scripting and automation.

---

## Why This Exists

Arch Linux expects users to review news updates regularly before upgrading core systems.

This utility assumes people occasionally get distracted or trust their memory too much. It automates the pre-update validation loop so energy can be focused on building tools rather than troubleshooting broken dependencies.

---

## Disclaimer

This utility reduces upgrade risks; it does not eliminate them.

---

## License

MIT License. Break your system freely.
