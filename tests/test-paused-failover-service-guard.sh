#!/bin/sh
set -eu
F=mptcp-suite-routing/files/etc/init.d/mptcp-paused-failover
grep -Fq 'uci -q get mptcp_suite.failover.enabled' "$F"
grep -Fq '[ "$enabled" = 1 ] || return 0' "$F"
grep -Fq '[ -e /etc/mptcp-suite/paused ] || return 0' "$F"
E="$(grep -n 'enabled.*return 0' "$F" | cut -d: -f1)"
P="$(grep -n 'procd_open_instance' "$F" | cut -d: -f1)"
[ "$E" -lt "$P" ]
echo PAUSED_FAILOVER_SERVICE_GUARD_V7_OK
