#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-activate}"
sh -n "$F"
for X in MPTCP_ACTIVATE_DRY_RUN MPTCP_ACTIVATE_OK MPTCP_ACTIVATE_ROLLBACK MPTCP_ROUTING_SNAPSHOT MPTCP_RESUME; do grep -Fq "$X" "$F"; done
for X in precheck snapshot_direct routing tunnel profile_restart reconnect sync validate; do grep -Fq "STAGE=$X" "$F"; done
! grep -Fq 'rm -f "$PAUSED"' "$F" || true
echo MPTCP_ACTIVATE_STRUCTURE_OK

grep -Fq 'MPTCP_ROUTING_APPLY=1' "$F"
grep -Fq 'mptcp-routing-apply.log' "$F"
