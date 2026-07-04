# Runbook 09 — SCEP Certificate Profile

## Objective

Deploy a device certificate via SCEP (Simple Certificate Enrolment Protocol) through Intune, so devices can authenticate to Wi-Fi/VPN without a username/password — the standard "certificate-based auth" pattern.

## Prerequisites

- Completed [04-windows-autopilot.md](04-windows-autopilot.md) or [03-macos-ade-enrolment.md](03-macos-ade-enrolment.md) — at least one enrolled test device
- Read [notes/scep-explained.md](../notes/scep-explained.md) first — it has the SCEP flow diagram and vocabulary this runbook assumes
- A Certificate Authority (CA) reachable by Intune. For a lab without an on-prem CA + NDES server, use one of:
  - A trial of a cloud SCEP/PKI service (several vendors offer this, check current trial availability)
  - A minimal test setup with Windows Server AD CS + NDES role, if I have a lab VM available
  - If neither is feasible, complete this runbook as a **desk exercise**: build the trusted root certificate profile and the SCEP profile in Intune fully, note in "What I Broke On Purpose" that live enrolment wasn't possible, and record what error/state is expected without a reachable CA

## Steps

1. **Deploy the trusted root certificate profile first**
   1. Go to **Devices > Configuration > Create > New Policy > Trusted certificate**.
   2. Upload the root CA's `.cer` file.
      - `[screenshot: trusted root cert profile]`
   3. Assign to `Lab-Test-Devices`.
2. **Create the SCEP certificate profile**
   1. Go to **Devices > Configuration > Create > New Policy > SCEP certificate**.
   2. Certificate type: **Device**. Subject name format: `CN={{DeviceName}}` (or a serial/UPN variant).
   3. Key usage: Digital signature + Key encipherment. Key size: 2048.
   4. Extended key usage: Client Authentication.
   5. Root certificate: select the trusted root profile from step 1.
   6. SCEP server URL(s): point at the NDES/SCEP server endpoint (or cloud PKI connector endpoint).
      - `[screenshot: SCEP profile configuration]`
   7. Assign to `Lab-Test-Devices`.
      - `[screenshot: assignment]`
3. **Verify certificate issuance**
   1. On the test device, check the certificate store: Windows — `certmgr.msc` (Personal > Certificates); macOS — Keychain Access (System keychain).
      - `[screenshot: issued certificate visible in cert store]`
   2. In Intune, check **Devices > Monitor > Certificates** (or the device's certificate status blade) to confirm Intune also sees it as issued.
      - `[screenshot: Intune certificate status]`
4. **Use the certificate in a Wi-Fi or VPN profile (if applicable)**
   1. Create a Wi-Fi profile that references the SCEP certificate for EAP-TLS authentication, assign to the same group.
      - `[screenshot: Wi-Fi profile referencing SCEP cert]`
   2. Test connecting to the test SSID/VPN and confirm no username/password prompt appears — auth happens silently via the cert.
      - `[screenshot: successful cert-based connection]`

## What I Broke On Purpose

_Fill in after doing the work. Example prompts: What happens if the SCEP profile's root certificate reference doesn't match the actual CA — does the device fail silently or show an explicit error in the certificate status blade? What happens if I let the NDES service account password expire (or simulate it by pointing at an unreachable URL)?_

-

## What I Learned

_Fill in after doing the work._

-

## Production Considerations

- NDES (Network Device Enrolment Service) has known scaling/security quirks — the NDES connector needs monitoring, and its service account password rotation is a classic outage cause in real environments.
- Certificate renewal should happen automatically before expiry (SCEP profiles support a renewal threshold) — monitor certificate expiry proactively rather than waiting for auth failures.
- Subject name and SAN (Subject Alternative Name) format must exactly match what the Wi-Fi/VPN/RADIUS server expects — mismatches are the most common cause of "cert issued fine but auth still fails."
- See [notes/scep-explained.md](../notes/scep-explained.md) for the full troubleshooting checklist used when a cert-based Wi-Fi/VPN connection fails.
