#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-resume-safe

sh -n "$F"
grep -Fq 'tunnel-profiles.tsv' "$F"
grep -Fq 'ERROR=missing_profile_manifest' "$F"
grep -Fq 'ERROR=missing_tunnel_backup:$ID' "$F"
grep -Fq 'xray run -test -c "$SNAP"' "$F"
grep -Fq 'profiles=$COUNT' "$F"
! grep -Eq 'main|limit5|5mbps|12345|12346' "$F"

echo RESUME_SAFE_GENERIC_OK
