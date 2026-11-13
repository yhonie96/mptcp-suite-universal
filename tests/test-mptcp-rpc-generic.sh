#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp

sh -n "$F"
"$F" list | jsonfilter -e '@.status' >/dev/null

grep -Fq 'mptcp-profile-backup' "$F"
grep -Fq 'mptcp-profile-restart' "$F"
grep -Fq 'tunnel-profiles.tsv' "$F"
grep -Fq 'cleanup_staged()' "$F"
grep -Fq 'restore_profiles()' "$F"
grep -Fq 'direct_mode reuse' "$F"
grep -Fq '[ "$COUNT" -gt 0 ] || XRAY=0' "$F"

! grep -Eq 'xray-5mbps|/etc/xray/config|MAIN=|LIMIT=|TMAIN=|TLIMIT=' "$F"

grep -Fq "mptcp-pause-rollback.log" "$F"
grep -Fq "rollback tunnel belum sehat" "$F"
grep -Fq "check_http()" "$F"
grep -Fq "direct_http_not_ready" "$F"
grep -Fq "check_http >/dev/null" "$F"
grep -Fq "jeda tetap dipertahankan" "$F"
grep -Fq "MPTCP_RESUME=1 /usr/sbin/mptcp-reconnect" "$F"
echo MPTCP_RPC_GENERIC_OK
