#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-profile-backup

sh -n "$F"
grep -Fq '/usr/sbin/mptcp-profile-list' "$F"
grep -Fq 'TMPMANIFEST="/tmp/tunnel-profiles-$$.tsv"' "$F"
grep -Fq 'BACKUP="$DIR/tunnel-$ID.json"' "$F"
grep -Fq '"${1:-}" = check' "$F"
grep -Fq 'xray run -test -c "$CFG"' "$F"
! grep -Eq 'main|limit5|xray-5mbps|12345|12346' "$F"

echo PROFILE_BACKUP_HELPER_OK
