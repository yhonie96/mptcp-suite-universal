#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-reconnect
sh -n "$F"
grep -Fq '/usr/sbin/mptcp-profile-restart' "$F"
grep -Fq 'if [ "$N" -ge 1 ]; then' "$F"
grep -Fq '/etc/mptcp-suite/paused' "$F"
grep -Fq 'MPTCP_RESUME' "$F"
grep -Fq 'status jeda; reconnect dilewati' "$F"
! grep -Eq 'xray-5mbps|/etc/xray/config|main|limit5|12345|12346' "$F"
grep -Fq 'mptcp_suite.routing.tproxy_table' "$F"
grep -Fq 'ip route replace local 0.0.0.0/0 dev lo table "$TT"' "$F"
! grep -Fq "ip rule add pref 100" "$F"
echo RECONNECT_GENERIC_OK
