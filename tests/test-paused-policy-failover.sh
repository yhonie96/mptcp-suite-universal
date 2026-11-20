#!/bin/sh
set -eu
H=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-policy-failover
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
grep -Fq 'PAUSED_POLICY_ROUTE_OK' "$H"
grep -Fq 'OK=SECONDARY' "$H"
grep -Fq 'MPTCP_PAUSED_POLICY_FAILOVER_BIN' "$M"
grep -Fq 'policy_primary_fallback' "$M"
grep -Fq 'policy_secondary_restore' "$M"
grep -Fq 'SFC=' "$M"; grep -Fq 'SRC=' "$M"; grep -Fq 'PMODE=' "$M"
echo PAUSED_POLICY_FAILOVER_V10_OK
