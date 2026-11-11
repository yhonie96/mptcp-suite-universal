#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/etc/mptcp-suite/make-direct.uc
IN=luci-app-mptcp-suite/files/usr/share/mptcp-suite/xray-profile-template.json
OUT="/tmp/make-direct-test-$$.json"
trap 'rm -f "$OUT"' EXIT

ucode "$F" "$IN" "$OUT" vless-profile direct-profile
jq -e 'type=="object"' "$OUT" >/dev/null
jq -e '
 ([.routing.rules[]|select(.outboundTag=="vless-profile")]|length)==0 and
 ([.routing.rules[]|select(.outboundTag=="direct-profile")]|length)>=1
' "$OUT" >/dev/null
! grep -Eq 'vless-5mbps|direct-5mbps|/etc/xray' "$F"
echo MAKE_DIRECT_GENERIC_OK
