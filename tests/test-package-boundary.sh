#!/bin/sh
set -eu

PKG=mptcp-suite-dual-xray
UMENU=luci-app-mptcp-suite/files/usr/share/luci/menu.d/luci-app-mptcp-suite.json
DMENU=$PKG/files/usr/share/luci/menu.d/mptcp-suite-dual-xray.json

test -f "$PKG/Makefile"
grep -q 'PKG_NAME:=mptcp-suite-dual-xray' "$PKG/Makefile"
test -f "$DMENU"

python3 -m json.tool "$UMENU" >/dev/null
python3 -m json.tool "$DMENU" >/dev/null

for KEY in xray xray5 traffic-rules; do
 grep -Fq "\"admin/status/mptcp-suite/$KEY\"" "$DMENU"
 ! grep -Fq "\"admin/status/mptcp-suite/$KEY\"" "$UMENU"
done

! grep -Eq 'luci-app-xray-manager|luci-app-xray-5mbps-manager' "$UMENU"

echo PACKAGE_BOUNDARY_MENU_SPLIT_OK
