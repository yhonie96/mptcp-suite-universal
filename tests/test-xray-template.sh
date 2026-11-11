#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/share/mptcp-suite/xray-profile-template.json

jq -e . "$F" >/dev/null
! grep -Eq '103\.147|3443|3444|12345|12346' "$F"

for P in SERVER UUID SNI REALITY_KEY SHORT_ID; do
 grep -q "${P}_PLACEHOLDER" "$F"
done

test "$(jq -r '.inbounds[0].tag' "$F")" = "tproxy-profile"
jq -e '.outbounds[]|select(.tag=="freedom-profile")' "$F" >/dev/null
jq -e '.outbounds[]|select(.tag=="vless-profile")' "$F" >/dev/null
jq -e '.outbounds[]|select(.tag=="direct-profile")' "$F" >/dev/null

echo XRAY_GENERIC_TEMPLATE_OK

B=luci-app-mptcp-suite/files/usr/libexec/rpcd/xray-profile-builder
grep -Fq 'TEMPLATE=/usr/share/mptcp-suite/xray-profile-template.json' "$B"
grep -Fq 'tag=="freedom-profile"' "$B"
grep -Fq 'tag=="vless-profile"' "$B"
! grep -Eq 'xray-5mbps|12345|12346|3443|3444' "$B"
echo XRAY_GENERIC_BUILDER_OK
