# macOS Packaging

Scripts for building a macOS `.pkg` installer from scratch using Apple's native
`pkgbuild`/`productbuild` tools, for deployment as an Intune Line-of-business app.

## Files

| File | Purpose |
|---|---|
| `build-pkg.sh` | Builds a trivial demo payload into a component package, then wraps it into a distribution package |
| `scripts/postinstall` | Example postinstall script run by the installer after the payload is copied |

## Run it

```bash
cd scripts/packaging/macos
chmod +x build-pkg.sh scripts/postinstall   # if permissions were lost (e.g. after git clone)
./build-pkg.sh
```

Output lands in `./build/LabDemo-1.0.pkg` (gitignored — build artifacts, not source).

## Component package vs. distribution package

- **Component package** (`pkgbuild`): the basic building block. Says "copy these files to this location on disk, then optionally run a postinstall script." No UI, no install requirement checks, can't bundle multiple components.
- **Distribution package** (`productbuild`): wraps one or more component packages into the polished `.pkg` you'd actually ship. Supports install requirement checks (minimum OS version, architecture), a welcome/license/readme screen, and multiple components in one package.

Intune (and most MDM-driven deployments) expect a single distribution-style `.pkg` file, so `build-pkg.sh` always produces one, even though this demo only has one trivial component inside it.

## Postinstall scripts

`scripts/postinstall` runs **as root**, **after** the payload files are already on disk. A few things that matter in practice:

- It must be named exactly `postinstall` (no file extension) and be executable (`chmod +x`) for `pkgbuild --scripts` to pick it up automatically.
- Exit code 0 = success. Any non-zero exit tells the installer (and Intune) the install failed — even though the payload was already copied — so make the script idempotent and safe to re-run.
- Because it runs as root, treat it with the same care as any other root-level script: no hardcoded secrets, no destructive assumptions about existing state.

## Signing (not done by default in this lab)

The demo package built by `build-pkg.sh` is **unsigned** — there's a commented-out `productsign` step in the script showing exactly what to run if you have a Developer ID Installer certificate. Real production packages should always be signed (and ideally notarized); see [runbooks/07-macos-pkg-packaging.md](../../../runbooks/07-macos-pkg-packaging.md) for what to test/observe with an unsigned package.
