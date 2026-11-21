<<<<<<< HEAD
# Handshake

Authorized WiFi handshake inspection toolkit. **Read-only verification only** —
this repo never attempts passphrase recovery.

> **Authorization required.** Only use on networks you own or have written
> permission to test. See `SECURITY.md` and `config/scope.conf`.

## Layout

```
bin/
  recon.sh     passive scan: interface info + visible BSS inventory
  capture.sh   gated capture for one BSSID already in scope.conf
  verify.sh    read-only capture quality check (EAPOL M1-M4, scope check)
config/
  scope.conf   BSSID allowlist — everything else refuses to run
captures/      gitignored, holds .pcapng + .22000
report/
  report-template.md
docs/
  methodology.md
SECURITY.md
handshake.sh   legacy scratch script, kept as-is, not wired up
```

## Quick start

```bash
# 0. list your own BSSID and add it to config/scope.conf
#    10:ab:cd:12:34:56   my-lab-ap   bench

# 1. see interfaces and nearby APs (no injection)
sudo apt install iw tshark
./bin/recon.sh              # list interfaces
./bin/recon.sh wlan0mon     # inventory around wlan0mon

# 2. capture (requires hcxdumptool + hcxpcapngtool)
sudo apt install hcxdumptool
./bin/capture.sh wlan0mon 10:ab:cd:12:34:56 300

# 3. verify quality and scope compliance
./bin/verify.sh captures/10-ab-cd-12-34-56-20260101-120000.pcapng

# 4. fill in the report
cp report/report-template.md report/engagement-$(date +%Y%m%d).md
```

## What `verify.sh` checks

1. Every BSSID in the capture appears in `config/scope.conf` — otherwise it
   stops and tells you to destroy the file.
2. EAPOL-Key message numbers per BSSID.
3. Nonce and MIC presence on each key frame.
4. Whether M1–M4 are all present, or which ones are missing.

Exit code `0` = complete and in scope. Exit code `1` = incomplete or out of scope.

## Design rules

- `recon.sh` — no writes, no injection.
- `capture.sh` — gated on `scope.conf`, deauth disabled by default.
- `verify.sh` — strictly read-only, refuses out-of-scope captures.
- No key recovery, no wordlists, no MIC comparison. Out of scope for this repo.

## Dependencies

| Tool | Used by | Package |
|---|---|---|
| `iw` | recon, capture | `iw` |
| `tshark` | verify | `tshark` |
| `hcxdumptool` | capture | `hcxdumptool` |
| `hcxpcapngtool` | capture | `hcxdumptool` |
| `python3` | verify (verdict) | preinstalled |

## Further reading

- `docs/methodology.md` — full workflow, tool choice, common failure modes.
>>>>>>> 88804d0 (Initial commit)
