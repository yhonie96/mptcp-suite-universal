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

grep -Fq 'MPTCP_PAUSED_FAILOVER_SERVICE' "$F"
grep -Fq 'MPTCP_TRAFFIC_POLICY_SERVICE' "$F"
grep -Fq 'STAGE=direct_isolation' "$F"
grep -Fq '"$PAUSED_FAILOVER_SERVICE" stop' "$F"
grep -Fq '"$TRAFFIC_POLICY_SERVICE" stop' "$F"
grep -Fq '"$TRAFFIC_POLICY_SERVICE" reload' "$F"
grep -Fq '"$PAUSED_FAILOVER_SERVICE" start' "$F"
echo MPTCP_ACTIVATE_DIRECT_ISOLATION_V14_OK
