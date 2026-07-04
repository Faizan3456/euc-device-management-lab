#!/bin/bash
#
# check-mdm-enrolment.sh
#
# Verifies a Mac's MDM/ADE enrolment state from the terminal, independent of
# what the Intune admin console says. Useful for confirming enrolment right
# after Setup Assistant, or troubleshooting a device that Intune claims is
# enrolled but is behaving oddly.
#
# Uses two built-in macOS tools:
#   - `profiles status -type enrollment`  -> MDM enrolment state as macOS sees it
#   - `system_profiler SPConfigurationProfileDataType` -> installed config profiles,
#     including the MDM profile itself, useful to confirm it's actually present
#     and not just "pending".
#
# Run with sudo for the most complete output (profiles needs elevated access
# to show full detail on some macOS versions).

set -uo pipefail

echo "=================================================="
echo " MDM / ADE Enrolment Check"
echo " Host: $(hostname)"
echo " Date: $(date)"
echo "=================================================="
echo ""

echo "--- 1. Enrollment status (profiles status -type enrollment) ---"
if [ "$EUID" -ne 0 ]; then
    echo "(Not running as root - some detail may be limited. Re-run with sudo for full output.)"
fi
profiles status -type enrollment
echo ""

echo "--- 2. Serial number (cross-check this against Apple Business Manager / Intune) ---"
system_profiler SPHardwareDataType | grep -E "Serial Number|Model Name|Model Identifier"
echo ""

echo "--- 3. Installed configuration profiles (looking for the MDM enrolment profile) ---"
system_profiler SPConfigurationProfileDataType 2>/dev/null | grep -E "Display Name|Profile Identifier|Organization" || \
    echo "No configuration profiles found, or system_profiler could not read them (try with sudo)."
echo ""

echo "--- 4. Quick interpretation guide ---"
cat <<'EOF'
- "MDM enrollment: Yes (User Approved)" is what you want for full Intune management
  (unapproved MDM enrolment has restricted capabilities on modern macOS).
- "Enrolled via DEP: Yes" confirms this device came in through Automated Device
  Enrolment (ADE) rather than a manual/BYOD-style enrolment.
- If a profile shows up in step 3 with an Organization matching your tenant name,
  the MDM profile is actually installed, not just assigned in the portal.
- If step 1 shows "MDM enrollment: No" but Intune's portal shows the device as
  enrolled, that's a real discrepancy worth investigating (stale record, or the
  device was wiped/re-imaged without Intune being told).
EOF
