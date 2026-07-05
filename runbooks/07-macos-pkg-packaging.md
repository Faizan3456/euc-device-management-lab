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

## What was done vs. what's blocked

The **build half is fully done and verified locally**; the **deploy half is blocked** on the same hardware gap as [03-macos-ade-enrolment.md](03-macos-ade-enrolment.md) — there is no enrolled test Mac in this lab (the only Mac is the daily-driver work machine, already enrolled in the employer's Mosyle MDM, which can't be re-enrolled). So the `.pkg` is built, inspected, and understood; uploading it to Intune and confirming an on-device install + postinstall is deferred until a test Mac is available.

## What I Broke On Purpose

- Ran `build-pkg.sh` — it built cleanly: `pkgbuild` produced the component package (`LabDemoComponent.pkg`), `productbuild` wrapped it into the distribution package (`LabDemo-1.0.pkg`). Verified the structure with `pkgutil --expand`, which showed the distribution package genuinely contains the component package, with the `postinstall` script in the component's `Scripts/` folder and the payload targeting `/Library/LabDemo/`.
- Left it **unsigned** (no Developer ID Installer certificate). `pkgutil --check-signature LabDemo-1.0.pkg` reports `Status: no signature`. The signing command is kept in the build script (commented out) so it's ready the moment a real cert exists.
- **Found a real macOS-packaging gotcha:** `pkgutil --payload-files LabDemo-1.0.pkg` showed the payload contained not just `./Library/LabDemo/hello.txt` but also AppleDouble sidecar files — `._hello.txt`, `._LabDemo`, `._Library`. macOS stores resource forks / extended attributes in these `._*` files, and building a payload on a Mac can silently sweep them into the package. Harmless here, but unprofessional and occasionally the cause of validation warnings — a clean package would strip them (e.g. `COPYFILE_DISABLE=1` in the environment, or `dot_clean` on the payload tree before `pkgbuild`).

## What I Learned

- **Component vs distribution package** is a real, concrete distinction, not just terminology: `pkgbuild` makes the component (payload + scripts, no UI), `productbuild` makes the distribution (wraps one or more components, adds install UI + requirement checks, and is what MDM / Installer.app actually expect). Intune's macOS LOB app upload wants the distribution `.pkg`.
- The `postinstall` script has strict rules `pkgbuild` enforces silently: it must be named exactly `postinstall` (no extension), be executable, and live in the folder passed to `--scripts`. It runs as **root** after the payload is copied, and its **exit code** is what tells the installer (and Intune) success/failure — so a payload can copy successfully but the app still report "failed" if the postinstall exits non-zero. Keep it idempotent.
- An unsigned package builds and inspects fine but carries no identity/integrity guarantee. Production macOS packages should be signed with a Developer ID Installer certificate **and** notarized; depending on delivery method Gatekeeper can otherwise block them, and any user who inspects the file sees "no signature."
- Always check `pkgutil --payload-files` on a package before shipping it — building payloads on a Mac can capture AppleDouble `._*` files, so the payload isn't always exactly what you intended.

## Production Considerations

- Production macOS packages should be signed with a Developer ID Installer certificate and notarized — unsigned/unnotarized packages can be blocked by Gatekeeper depending on how they're delivered, and always look unprofessional/risky to an end user if they ever see the raw file.
- Distribution packages (built with `productbuild`) support multiple component packages, install requirements/checks, and a friendlier install UI — real deployments should reach for this over a bare component package once there's more than one thing to install.
- Postinstall scripts run as root — treat them with the same care as any other root-level script (no hardcoded secrets, idempotent so re-running doesn't break things).
- For anything beyond a trivial demo, consider a proper packaging tool (like `munki-pkg` or a CI pipeline) instead of hand-running `pkgbuild`/`productbuild` each time.
