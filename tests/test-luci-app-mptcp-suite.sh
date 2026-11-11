#!/bin/sh
set -eu
P=luci-app-mptcp-suite
test -f "$P/Makefile"
test "$(find "$P/files" -type f | wc -l)" -ge 41
test "$(awk 'NR==26{print substr($0,1,1)=="\t"}' "$P/Makefile")" = 1
for F in "$P"/files/usr/libexec/rpcd/* "$P"/files/usr/sbin/* "$P"/files/etc/init.d/*; do
 sh -n "$F"
 test -x "$F"
done
! grep -RqiE '103\.147|192\.168\.(1|8)\.|eth1|phy0-sta0|WAN1|wwan|BEGIN.*PRIVATE' "$P/files"
grep -q 'json_add_string uuid ""' "$P/files/usr/libexec/rpcd/xray-manager"
grep -q 'json_add_string uuid ""' "$P/files/usr/libexec/rpcd/xray-5mbps-manager"
echo LUCI_APP_MPTCP_SUITE_TEST_OK

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
cp -a "$P/files/." "$ROOT/"
chmod 600 "$ROOT/etc/config/mptcp_profiles"
test "$(find "$ROOT" -type f | wc -l)" = "$(find "$P/files" -type f | wc -l)"
test "$(ls -l "$ROOT/etc/config/mptcp_profiles" | awk '{print $1}')" = "-rw-------"
cp -a "$P/files/." "$ROOT/"
chmod 600 "$ROOT/etc/config/mptcp_profiles"
rm -rf "$ROOT/usr" "$ROOT/www" "$ROOT/etc/init.d" "$ROOT/etc/mptcp-suite"
test -f "$ROOT/etc/config/mptcp_profiles"
echo LUCI_APP_INSTALL_UPGRADE_UNINSTALL_OK
