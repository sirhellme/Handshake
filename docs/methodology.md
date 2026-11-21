# Methodology

Planning-level notes. No recovery steps are documented here by design.

## 0. Authorization

Written sign-off first: named BSSIDs/SSIDs, location, time window, testers,
escalation contact. Then rules of engagement: is client disruption allowed,
how long may captures be held, where must they be destroyed.

Biggest risk in these engagements is not the target — it is accidentally
touching a neighbour's AP on the same channel. Every script here enforces
the allowlist before doing anything.

## 1. Lab baseline

| Item | Choice |
|---|---|
| AP | Router you own, or hostapd on Linux |
| Adapter | AR9271 / RTL8812AU / MT7612U — monitor + injection |
| Client | Phone/laptop you own, triggers reconnect on demand |
| Isolation | Separate VLAN, shielded room, or faraday bag |
| Knowns | Record PSK, SSID, channel, driver, kernel before the first run |

Everything later is compared against that baseline. If the known-good case
fails, debug the adapter before blaming the target.

## 2. Phases

1. **Recon** — inventory only. `bin/recon.sh`. No injection.
2. **Capture** — `bin/capture.sh`, gated on scope, deauth disabled.
3. **Verify** — `bin/verify.sh`. Confirm completeness *before* spending
   any further effort.
4. **Report** — `report/report-template.md`.

## 3. Tool choice

| Need | Tool | Why |
|---|---|---|
| Inventory | `iw scan` | Read-only, no capture, minimal footprint |
| Capture | `hcxdumptool` | Modern, PMKID + EAPOL, WPA3 transition aware |
| Conversion | `hcxpcapngtool` | Single canonical pcapng → 22000 path |
| Inspection | `tshark` | Message-level view, repeatable, scriptable |
| Reversible check | `verify.sh` | Scope gate + completeness in one pass |

Deliberately absent: `wifite2` and similar wrappers. Automation hides what is
actually happening, which is unacceptable inside a scoped engagement.

## 4. Capture quality dominates

A clean M1+M2 pair with both nonces beats any amount of downstream
compute. Validate early and reject bad captures instead of retrying blind.

Failure modes worth knowing:

- Adapter claims monitor mode but drops EAPOL frames — check with a known
  good baseline first.
- AP channel hops while capture is fixed — miss the reconnect.
- Capture starts mid-handshake — replay counter mismatch, unusable.
- Test traffic from an out-of-scope AP lands in the same file — `verify.sh`
  catches this and stops the run.
- Mesh/roaming frames that don't reflect the target PSK — verify BSSID
  every time.

## 5. Defensive recommendations (put these in the report)

- Prefer WPA3-SAE, or WPA2 with PMF (802.11w) where clients support it.
- Long random passphrases; length beats complexity rules.
- Disable WPS entirely.
- 802.1X/EAP for anything beyond home use.
- Retire hardware that only speaks WPA2-PSK without PMF.
- Monitor for deauth/disassociation floods.
