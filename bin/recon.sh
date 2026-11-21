#!/bin/bash
#
# recon.sh — passive inventory only. No injection, no deauth, no capture writes.
#
# Usage:
#   ./bin/recon.sh [interface]
#
# Requires: iw, iwconfig (optional), tshark (optional)

set -euo pipefail

IFACE="${1:-}"

command -v iw >/dev/null 2>&1 || {
  echo "error: 'iw' not installed (apt install iw)" >&2
  exit 1
}

if [[ -z "$IFACE" ]]; then
  echo "=== wireless interfaces ==="
  iw dev | awk '/Interface/ {print "  " $2}'
  echo
  echo "usage: $0 <interface>"
  exit 0
fi

if ! iw dev "$IFACE" info >/dev/null 2>&1; then
  echo "error: interface '$IFACE' not found" >&2
  exit 1
fi

echo "=== interface: $IFACE ==="
iw dev "$IFACE" info
echo

echo "=== regulatory / phy ==="
iw phy "$(iw dev "$IFACE" info | awk '/wiphy/ {print $2}')" info \
  | grep -E 'Band|Channel|HT|VHT|HE' | head -40 || true
echo

echo "=== visible BSSes (neighbours, no association) ==="
printf '%-19s %-4s %-18s %-6s %s\n' BSSID CHANNEL SECURITY SIGNAL SSID

# -w 3: short scan window, read-only
iw dev "$IFACE" scan 2>/dev/null | awk '
  /^BSS /            { bssid=$2; sub(/\(.*/, "", bssid) }
  /signal:/          { sig=$2 }
  /^[ \t]*freq:/     { freq=$2 }
  /^[ \t]*SSID:/     { ssid=substr($0, index($0,$2)); gsub(/^[ \t]+/, "", ssid) }
  /RSN:/             { rsn=1 }
  /WPA:/             { wpa=1 }
  /Authentication suites/ { auth=1 }
  /^$/ {
    if (bssid != "") {
      chan = (freq >= 5925) ? "6G" : ((freq >= 4910 && freq <= 5895) ? (freq-5000)/5 : ((freq == 2484) ? 14 : (freq-2407)/5))
      sec  = (rsn && wpa) ? "WPA/WPA2" : (rsn ? (auth ? "WPA2-EAP" : "WPA2-PSK") : (wpa ? "WPA" : "OPEN/WEP"))
      printf "%-19s %-4s %-18s %-6s %s\n", bssid, chan, sec, sig, (ssid == "" ? "<hidden>" : ssid)
    }
    bssid=""; sig=""; freq=0; ssid=""; rsn=0; wpa=0; auth=0
  }
'
echo
echo "next: add in-scope targets to config/scope.conf, then ./bin/capture.sh"
