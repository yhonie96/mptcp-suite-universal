#!/bin/sh
set -eu
for H in mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-managed-clear mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-rollback; do
 grep -Fq 'refresh_traffic_policy' "$H"
 grep -Fq 'traffic_policy_refresh_failed' "$H"
 grep -Fq 'MPTCP_TRAFFIC_POLICY_APPLY' "$H"
 [ "$(grep -n 'refresh_traffic_policy' "$H" | tail -n1 | cut -d: -f1)" -lt "$(grep -n 'ROUTING_.*_OK' "$H" | tail -n1 | cut -d: -f1)" ]
done
echo PAUSE_TRAFFIC_REFRESH_V10_OK
