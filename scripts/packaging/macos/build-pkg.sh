#!/bin/bash
#
# build-pkg.sh
#
# Builds a trivial demo macOS installer package using Apple's native packaging
# tools: pkgbuild (component package) and productbuild (distribution package).
#
# Component package vs distribution package, in simple English:
#   - A COMPONENT package (built by pkgbuild) is the basic unit: "put these files
#     at this destination, then optionally run this postinstall script." It's a
#     single flat installer with no UI customization and no support for bundling
#     multiple components together.
#   - A DISTRIBUTION package (built by productbuild) wraps one or more component
#     packages into the polished .pkg you'd actually hand to an end user or push
#     via MDM. It supports install requirements checks (e.g. minimum OS version),
#     a welcome/license/readme UI, and can bundle multiple component packages as
#     one distribution.
#
# In this demo we build ONE component package and wrap it in a distribution
# package, which is the realistic minimum for anything deployed through Intune -
# Intune expects a single .pkg file, and productbuild's output is what plays
# nicely with Installer.app / MDM-driven installs.
#
# This demo package is NOT signed (no Developer ID Installer certificate assumed).
# See the signing step below - it's commented out and explained, not deleted,
# so the exact command is here when you have a real cert to test with.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PAYLOAD_DIR="${BUILD_DIR}/payload"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

APP_IDENTIFIER="com.lab.demo.pkg"
APP_VERSION="1.0"
INSTALL_LOCATION="/Library/LabDemo"

COMPONENT_PKG="${BUILD_DIR}/LabDemoComponent.pkg"
DISTRIBUTION_PKG="${BUILD_DIR}/LabDemo-${APP_VERSION}.pkg"

echo "==> Cleaning previous build output"
rm -rf "${BUILD_DIR}"
mkdir -p "${PAYLOAD_DIR}${INSTALL_LOCATION}"

echo "==> Creating trivial payload"
# The payload is just what pkgbuild will copy to INSTALL_LOCATION on the target Mac.
# Replace this with your real app/files for anything beyond a demo.
cat > "${PAYLOAD_DIR}${INSTALL_LOCATION}/hello.txt" <<EOF
This file was installed by the EUC device management lab demo package.
Built at: $(date)
EOF

echo "==> Building component package with pkgbuild"
pkgbuild \
    --root "${PAYLOAD_DIR}" \
    --identifier "${APP_IDENTIFIER}" \
    --version "${APP_VERSION}" \
    --scripts "${SCRIPTS_DIR}" \
    --install-location "/" \
    "${COMPONENT_PKG}"

echo "==> Wrapping component package into a distribution package with productbuild"
# productbuild --package wraps a single component package with no extra
# requirements/UI. For a real deployment you'd typically author a distribution.xml
# (via `productbuild --synthesize`) to control the welcome/license screens and any
# volume/OS requirement checks - skipped here to keep the demo runnable as-is.
productbuild \
    --package "${COMPONENT_PKG}" \
    "${DISTRIBUTION_PKG}"

echo "==> Done. Distribution package created at:"
echo "    ${DISTRIBUTION_PKG}"

# --- Signing (uncomment and adjust if you have a Developer ID Installer cert) ---
# Real production packages should always be signed. Without a cert, Gatekeeper/
# Intune may still install it, but you lose the integrity/identity guarantee a
# signed package gives you, and it looks untrustworthy if a user ever inspects it.
#
# SIGNED_PKG="${BUILD_DIR}/LabDemo-${APP_VERSION}-signed.pkg"
# productsign --sign "Developer ID Installer: Your Name (TEAMID)" \
#     "${DISTRIBUTION_PKG}" "${SIGNED_PKG}"
# pkgutil --check-signature "${SIGNED_PKG}"

echo ""
echo "To verify locally before uploading to Intune:"
echo "  pkgutil --payload-files ${DISTRIBUTION_PKG}"
echo "  installer -pkg ${DISTRIBUTION_PKG} -target / -dumplog   # (dry-run style info, still requires sudo to actually install)"
