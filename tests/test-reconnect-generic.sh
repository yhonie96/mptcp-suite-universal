#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-reconnect
sh -n "$F"
grep -Fq '/usr/sbin/mptcp-profile-restart' "$F"
grep -Fq 'if [ "$N" -ge 1 ]; then' "$F"
! grep -Eq 'xray-5mbps|/etc/xray/config|main|limit5|12345|12346' "$F"
echo RECONNECT_GENERIC_OK
