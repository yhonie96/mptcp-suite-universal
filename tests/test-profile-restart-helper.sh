#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-profile-restart
sh -n "$F"
grep -Fq '/usr/sbin/mptcp-profile-list' "$F"
grep -Fq '"${1:-}" = check' "$F"
grep -Fq 'xray run -test -c "$CFG"' "$F"
grep -Fq '/etc/init.d/"$SVC" restart' "$F"
! grep -Eq 'main|limit5|xray-5mbps|12345|12346' "$F"
echo PROFILE_RESTART_HELPER_OK
