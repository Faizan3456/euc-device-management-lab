# Intune vs. Workspace ONE — Concept Mapping

Interviewers sometimes come from a Workspace ONE (VMware/Omnissa) background, or ask
"have you used other UEM platforms?" This table maps the same underlying concept
across both products, in plain English, so I can translate on the fly.

| Concept | Microsoft Intune term | Workspace ONE term | Plain-English explanation |
|---|---|---|---|
| A set of settings pushed to a device | Configuration profile | Profile | A bundle of settings (Wi-Fi, restrictions, VPN, etc.) sent to devices to configure them without the user doing it manually |
| A rule that decides "healthy" vs "unhealthy" device | Compliance policy | Compliance policy | Defines the minimum bar a device must meet (encryption, OS version, passcode) to be trusted |
| A group that updates its members automatically based on rules | Dynamic group (Entra ID) | Smart group | A group whose membership is calculated automatically from attributes (department, OS, device type) instead of manually adding people/devices |
| Dashboards/analytics about device health and usage | Intune reporting / Endpoint analytics | Workspace ONE Intelligence | Data and dashboards about device compliance, app usage, performance, and trends across the fleet |
| Zero-touch provisioning for Windows | Windows Autopilot | Workspace ONE (Windows) drop-ship provisioning | A device ships straight from the OEM/reseller to the end user, and auto-configures itself into the company's management on first boot |
| Zero-touch provisioning for Apple devices | Automated Device Enrolment (ADE), via Apple Business Manager | Also uses ADE via Apple Business Manager (UEM-agnostic) | Same underlying Apple technology — Apple's ADE is not Microsoft- or VMware-specific, both UEMs plug into it the same way |
| The app end users install to self-enrol / see managed apps | Company Portal | Intelligent Hub (formerly Hub / AirWatch Agent) | The app a user opens to enrol their device, install company apps, and check compliance status |
| Enterprise app catalog/store | Company Portal (app list) | Hub Catalog | Where an end user browses and installs apps their org has approved for them |
| Certificate delivery to devices | SCEP / PKCS certificate profile | SCEP / PKCS profile | Automatically issues a device or user certificate for Wi-Fi/VPN/email auth without a human requesting it |
| Managing only work data on a personal device | App protection policy (MAM without enrolment) | App configuration / MAM (via AirWatch SDK/Wrapping) | Protects company data inside an app (e.g. Outlook) without managing the whole device — used for BYOD |
| Wiping a device remotely | Retire / Wipe (Intune actions) | Enterprise Wipe / Device Wipe | Retire = removes company data/profiles only (BYOD-friendly); Wipe = factory resets the whole device |
| Grouping devices/updates into waves | Update rings (Windows Update for Business) | Also called "Update rings"/staged deployment in newer Workspace ONE UEM releases | Rolling updates out to a small group first (pilot), then wider groups, instead of all at once |
| Underlying identity provider | Microsoft Entra ID | Can integrate with Entra ID, Okta, or Workspace ONE Access | The system that actually authenticates users; the UEM platform relies on it rather than replacing it |
| Access control based on device/user risk | Conditional Access (with Entra ID) | Workspace ONE Access policies (often paired with Okta/Entra) | Blocking or allowing access to company resources based on signals like device compliance, location, or risk level |
| Console/portal for admins | Intune admin center (intune.microsoft.com) | Workspace ONE UEM Console | The web interface where IT configures policies, apps, and views devices |

## Things that are conceptually identical, just named differently

Most core UEM concepts map 1:1 across platforms because they're solving the same
problem (enrol a device, configure it, keep it healthy, deploy apps, retire it
safely) — the terminology differs, but the *shape* of the workflow is nearly
universal across Intune, Workspace ONE, Jamf, and MobileIron/Ivanti. Naming the
underlying concept correctly, even with the "wrong" vendor's word, usually reads
fine in an interview.
