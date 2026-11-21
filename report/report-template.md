# Findings report

| Field | Value |
|---|---|
| Engagement | _name / reference_ |
| Authorization | _who signed off, date_ |
| Tester | _your name_ |
| Window | _start – end (with timezone)_ |
| Equipment | _adapter model, driver, kernel_ |

## Scope

| BSSID | SSID | Channel | In scope | Notes |
|---|---|---|---|---|
|  |  |  |  |  |

## Method

1. Passive recon (`iw scan`) — inventory only.
2. Channel-locked passive capture (`hcxdumptool`, deauth disabled).
3. Capture quality verification (`bin/verify.sh`) — EAPOL M-count, nonces, MIC.
4. _further steps as authorized_

## Findings

### F-01 <title>

- **Severity**: High / Medium / Low / Info
- **Affected**: _BSSID / SSID_
- **Evidence**: `captures/…`, `verify.sh` output snippet
- **Detail**: _what was observed, not how to exploit_
- **Remediation**: _concrete fix_
- **Retest criteria**: _what changes the finding to closed_

## Observations (no severity)

- e.g. adjacent AP visible on same channel — out of scope, noted for awareness.

## Capture handling

- Files retained: _list_
- Retention policy: _destroy after retest_
- Destroyed on: _date, method_
