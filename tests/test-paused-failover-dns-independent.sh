#!/bin/sh
set -eu
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
R=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-route
! grep -Fq '"$CURL" --interface' "$M"
grep -Fq 'MPTCP_PING_BIN' "$M"
grep -Fq 'mptcp_suite.failover.probe_ip_primary' "$M"
grep -Fq '"$PING" -c 1 -W 2 -I "$1" "$PROBE_IP_PRIMARY"' "$M"
grep -Fq '"$PING" -c 1 -W 2 -I "$1" "$PROBE_IP_SECONDARY"' "$M"
grep -Fq 'MPTCP_PING_BIN' "$R"
grep -Fq 'probe_validation_failed' "$R"
! grep -Fq 'http_validation_failed' "$R"
echo PAUSED_FAILOVER_DNS_INDEPENDENT_V8_OK
