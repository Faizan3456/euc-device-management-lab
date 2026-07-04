# Runbook 07 — macOS .pkg Packaging

## Objective

Build a macOS `.pkg` installer from scratch using Apple's native tools (`pkgbuild`/`productbuild`), deploy it through Intune as a "Line-of-business app," and understand the difference between a component package and a distribution package.

## Prerequisites

- Completed [03-macos-ade-enrolment.md](03-macos-ade-enrolment.md) — at least one enrolled test Mac
- A Mac with Xcode command line tools installed (`xcode-select --install`) for `pkgbuild`/`productbuild`
- [scripts/packaging/macos/build-pkg.sh](../scripts/packaging/macos/build-pkg.sh)

## Steps

1. **Build the demo package**
   1. Run [scripts/packaging/macos/build-pkg.sh](../scripts/packaging/macos/build-pkg.sh) — it creates a trivial payload (a text file dropped into `/Library/LabDemo/`), builds a component package with `pkgbuild`, wraps it into a distribution package with `productbuild`, and includes a postinstall script.
      - `[screenshot/terminal output: build-pkg.sh run, .pkg produced]`
2. **(Optional but recommended for real interview prep) Sign the package**
   1. If I have an Apple Developer ID Installer certificate, sign with `productsign --sign "Developer ID Installer: My Name (TEAMID)"`.
   2. If not (lab default), note in "What I Learned" what Gatekeeper/Intune says about an unsigned pkg, since real production packages are always signed.
      - `[screenshot: codesign/pkgutil --check-signature output]`
3. **Upload to Intune**
   1. Go to **Apps > macOS > Add > macOS app (Line-of-business app)**, upload the `.pkg`.
      - `[screenshot: app upload]`
   2. Fill app info, minimum OS version, ignore app version if the installer doesn't expose one cleanly.
   3. Assign as **Required** to `Lab-Test-Devices`.
      - `[screenshot: assignment]`
4. **Deploy and verify**
   1. Sync the test Mac (System Settings > General > Device Management, or wait for check-in).
   2. Confirm install status in **Apps > Monitor > App install status**.
      - `[screenshot: install status]`
   3. On the Mac, confirm the payload landed and the postinstall script ran (check `/Library/LabDemo/` and `/var/log/install.log` for the postinstall echo statement).
      - `[screenshot: terminal showing payload + postinstall evidence]`

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if I deploy the unsigned package — does Intune reject it outright, or install it anyway with a Gatekeeper warning? What happens if the postinstall script exits non-zero — does Intune mark the app as failed?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- Production macOS packages should be signed with a Developer ID Installer certificate and notarized — unsigned/unnotarized packages can be blocked by Gatekeeper depending on how they're delivered, and always look unprofessional/risky to an end user if they ever see the raw file.
- Distribution packages (built with `productbuild`) support multiple component packages, install requirements/checks, and a friendlier install UI — real deployments should reach for this over a bare component package once there's more than one thing to install.
- Postinstall scripts run as root — treat them with the same care as any other root-level script (no hardcoded secrets, idempotent so re-running doesn't break things).
- For anything beyond a trivial demo, consider a proper packaging tool (like `munki-pkg` or a CI pipeline) instead of hand-running `pkgbuild`/`productbuild` each time.
