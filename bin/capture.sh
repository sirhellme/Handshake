#!/bin/bash
#
# capture.sh — capture EAPOL/PMKID frames for ONE in-scope BSSID.
#
# Passively waits for a natural reconnect. Does not send deauth by default.
#
# Usage:
#   ./bin/capture.sh <interface> <bssid> [seconds]
#
# Example:
#   ./bin/capture.sh wlan0mon aa:bb:cc:dd:ee:ff 300
#
# Requires: hcxdumptool, hcxpcapngtool, tshark, iw
# Writes:   captures/<bssid>-<timestamp>.pcapng

set -euo pipefail

IFACE="${1:-}"
BSSID="${2:-}"
SECONDS_TO_RUN="${3:-300}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="$ROOT/config/scope.conf"

die() { echo "error: $*" >&2; exit 1; }

[[ -n "$IFACE" && -n "$BSSID" ]] || die "usage: $0 <interface> <bssid> [seconds]"
[[ -r "$SCOPE" ]] || die "missing $SCOPE"

for tool in hcxdumptool hcxpcapngtool tshark iw; do
  command -v "$tool" >/dev/null 2>&1 || die "'$tool' not installed"
done

# ---- scope gate ------------------------------------------------------------
BSSID_LC="${BSSID,,}"
if ! awk -v b="$BSSID_LC" '
  /^[[:space:]]*#/ { next }
  NF >= 2         { if (tolower($1) == b) found = 1 }
  END             { exit(found ? 0 : 1) }
' "$SCOPE"; then
  die "BSSID $BSSID_LC is not listed in config/scope.conf — refusing to capture"
fi

iw dev "$IFACE" info >/dev/null 2>&1 || die "interface '$IFACE' not found"

# ---- capture ---------------------------------------------------------------
mkdir -p "$ROOT/captures"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/captures/${BSSID_LC//:/-}-$STAMP.pcapng"
CHAN="$(iw dev "$IFACE" info | awk '/channel/ {print $2; exit}')"
[[ -n "$CHAN" ]] || die "could not read channel from $IFACE"

echo "scope      : OK ($BSSID_LC)"
echo "interface  : $IFACE (channel $CHAN)"
echo "duration   : ${SECONDS_TO_RUN}s"
echo "output     : $OUT"
echo

# passive: listen on the AP channel, no deauth, no probe flood
sudo hcxdumptool -i "$IFACE" -c "$CHAN" -w "$OUT" \
  --disable_deauthentication \
  --disable_disassociation \
  --tot="$SECONDS_TO_RUN" || true

[[ -s "$OUT" ]] || die "no capture written"

echo
echo "=== capture summary ==="
hcxpcapngtool -o "${OUT%.pcapng}.22000" "$OUT" 2>&1 | tail -20 || true
echo
echo "next: ./bin/verify.sh $OUT"
