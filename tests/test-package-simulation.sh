#!/bin/sh
set -eu
U=luci-app-mptcp-suite/files
D=mptcp-suite-dual-xray/files
! find "$U" -type f | grep -Eq "xray-5mbps-manager|xray-manager.js|xray-traffic-rules|xray-policy-apply-draft"
! grep -Eq "config profile|12345|12346|3443|3444" "$U/etc/config/mptcp_profiles"
for F in etc/init.d/xray-5mbps usr/libexec/rpcd/xray-manager usr/libexec/rpcd/xray-5mbps-manager usr/libexec/rpcd/xray-traffic-rules; do test -f "$D/$F"; done
test -x "$D/etc/init.d/xray-dns"
test -x "$D/usr/bin/update-xray-geodata"
test -f "$D/etc/xray-dns/config.json"
test -f "$D/etc/uci-defaults/99-mptcp-xray-geodata"
test "$(grep -c update-xray-geodata "$D/etc/uci-defaults/99-mptcp-xray-geodata")" = 1
test "$(ls -l "$D/etc/xray-dns/config.json" | awk '{print $1}')" = "-rw-------"
grep -Fq "/etc/xray-dns/config.json" mptcp-suite-dual-xray/Makefile
grep -Fq "+curl" mptcp-suite-dual-xray/Makefile
test "$(jq -r '.dns.hosts["geosite:category-ads-all"]' "$D/etc/xray-dns/config.json")" = "#3"
sh -n "$D/etc/init.d/xray-dns"
sh -n "$D/usr/bin/update-xray-geodata"
echo PACKAGE_SIMULATION_OK
