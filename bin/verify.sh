#!/bin/bash
#
# verify.sh — READ-ONLY capture quality check.
#
# Answers: is this capture usable, and does it only contain in-scope traffic?
# No passphrase work. No recovery. Pure inspection.
#
# Usage:
#   ./bin/verify.sh <capture.pcapng>
#
# Checks:
#   1. every BSSID present in the capture is in config/scope.conf
#   2. EAPOL-Key message count (M1-M4)
#   3. nonce presence and MIC presence on key frames
#   4. which frames are missing for a complete 4-way handshake
#
# Requires: tshark

set -euo pipefail

PCAP="${1:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="$ROOT/config/scope.conf"

die() { echo "error: $*" >&2; exit 1; }

[[ -f "$PCAP" ]] || die "usage: $0 <capture.pcapng>"
command -v tshark >/dev/null 2>&1 || die "'tshark' not installed (apt install tshark)"
[[ -r "$SCOPE" ]] || die "missing $SCOPE"

# ---- 1. scope check on captured BSSIDs -------------------------------------
echo "=== BSSIDs in capture vs scope.conf ==="

mapfile -t SEEN < <(tshark -r "$PCAP" -T fields -e wlan.bssid 2>/dev/null \
  | awk 'NF' | tr 'A-F' 'a-f' | sort -u)

if [[ ${#SEEN[@]} -eq 0 ]]; then
  die "no 802.11 frames found — is this a monitor-mode capture?"
fi

VIOLATIONS=0
for b in "${SEEN[@]}"; do
  if awk -v b="$b" '
      /^[[:space:]]*#/ { next }
      NF >= 2         { if (tolower($1) == b) found = 1 }
      END             { exit(found ? 0 : 1) }
    ' "$SCOPE"; then
    echo "  OK    $b"
  else
    echo "  OUT   $b  <-- not in scope.conf"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done

if [[ $VIOLATIONS -gt 0 ]]; then
  die "$VIOLATIONS out-of-scope BSSID(s) in capture — stop, destroy file, re-scope"
fi
echo

# ---- 2/3. EAPOL inventory ---------------------------------------------------
echo "=== EAPOL frames ==="

tshark -r "$PCAP" -Y "eapol" \
  -T fields \
  -e frame.number \
  -e wlan.bssid \
  -e eapol.keydes.msgnr \
  -e eapol.keydes.nonce \
  -e eapol.keydes.key_mic \
  -e eapol.keydes.replay_counter \
  2>/dev/null \
| awk '{
    fn=$1; bssid=$2; msgnr=$3; nonce=$4; mic=$5; rc=$6
    gsub(/0x0*:/, "", mic); gsub(/:00+/, "", mic)
    key = bssid ":" msgnr
    seen[key]++
    if (nonce != "" && nonce != "00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00") nonces[key] = "Y"
    if (mic   != "") mics[key] = "Y"
    if (rc    != "") rep[key] = rc
    total++
    printf "  frame %-6s bssid %s msg M%s nonce %s mic %s replay %s\n", \
      fn, bssid, (msgnr == "" ? "?" : msgnr), \
      (nonces[bssid ":" msgnr] ? "yes" : "no "), \
      (mics[bssid ":" msgnr]   ? "yes" : "no "), \
      (rep[bssid ":" msgnr]    ? "yes" : "no ")
  }
  END { if (total == 0) print "  (none found)" }'

echo

# ---- 4. completeness verdict -------------------------------------------------
echo "=== verdict ==="

python3 - "$PCAP" <<'PY'
import subprocess, sys, collections

pcap = sys.argv[1]
out = subprocess.run(
    ["tshark", "-r", pcap, "-Y", "eapol", "-T", "fields",
     "-e", "wlan.bssid", "-e", "eapol.keydes.msgnr"],
    capture_output=True, text=True).stdout

frames = collections.Counter()
for line in out.strip().splitlines():
    parts = line.split("\t")
    if len(parts) >= 2 and parts[1]:
        frames[(parts[0].lower(), parts[1])] += 1

by_bssid = collections.defaultdict(set)
for bssid, msgnr in frames:
    by_bssid[bssid].add(msgnr)

if not by_bssid:
    print("  no EAPOL-Key frames — capture is NOT usable")
    sys.exit(1)

ok = False
for bssid, msgs in sorted(by_bssid.items()):
    got = {int(m) for m in msgs if m.isdigit()}
    missing = {1, 2, 3, 4} - got
    if not missing:
        print(f"  {bssid}: complete 4-way handshake (M1-M4)")
        ok = True
    elif {1, 2} <= got:
        print(f"  {bssid}: partial — have M{sorted(got)}, missing M{sorted(missing)}")
        print("             PMKID may still be recoverable from M1 if present")
    else:
        print(f"  {bssid}: incomplete — have M{sorted(got)}, missing M{sorted(missing)}")

sys.exit(0 if ok else 1)
PY
