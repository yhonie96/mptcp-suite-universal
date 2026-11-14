#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp}"
sh -n "$F"
grep -Fq 'MPTCP_DIRECT_SNAPSHOT' "$F"
grep -Fq 'MPTCP_RESUME_CHECK' "$F"
grep -Fq 'MPTCP_ACTIVATE' "$F"
grep -Fq '"$DIRECT_SNAPSHOT" --apply' "$F"
grep -Fq '"$RESUME_CHECK"' "$F"
grep -Fq '"$ACTIVATE" --apply' "$F"
grep -Fq 'touch "$PAUSED"' "$F"
! grep -Fq 'Aktivasi diblokir: diversion transparan belum aman' "$F"
echo MPTCP_RPC_ACTIVATION_STRUCTURE_OK
