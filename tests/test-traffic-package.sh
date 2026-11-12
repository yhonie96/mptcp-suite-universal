#!/bin/sh
set -eu
P="$PWD/mptcp-suite-traffic"
test -f "$P/files/etc/config/traffic_policy"
test -f "$P/files/usr/libexec/rpcd/mptcp-suite-traffic"
test -f "$P/files/www/luci-static/resources/view/status/traffic-policy-manual.js"

for F in "$P"/files/usr/sbin/traffic-policy-* \
 "$P"/files/etc/init.d/traffic-policy \
 "$P"/files/usr/libexec/rpcd/mptcp-suite-traffic; do
 sh -n "$F"
 test -x "$F"
done

grep -q "object: 'mptcp-suite-traffic'" \
 "$P/files/www/luci-static/resources/view/status/traffic-policy-manual.js"
grep -q "method: 'apply'" \
 "$P/files/www/luci-static/resources/view/status/traffic-policy-manual.js"

! grep -RInE 'phy0-sta0|0x102|192\.168\.2\.1|xray-traffic-rules|apply_manual' \
 "$P/files"

grep -q 'network.lan.device' "$P/files/usr/sbin/traffic-policy-generate"
grep -q 'mptcp_suite.routing.policy_mark' "$P/files/usr/sbin/traffic-policy-generate"
grep -q 'hook prerouting priority mangle - 2' "$P/files/usr/sbin/traffic-policy-generate"
grep -q 'traffic_manual_' "$P/files/usr/sbin/traffic-policy-apply"

grep -Fq "traffic_policy.main.mark_wwan" "$P/files/usr/sbin/traffic-policy-generate"
grep -Fq "nft list table ip traffic_policy" "$P/files/usr/sbin/traffic-policy-apply"
echo TRAFFIC_PACKAGE_10_CHECKS_OK
