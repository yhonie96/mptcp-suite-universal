#!/bin/sh
set -eu
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
R=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-route
C=mptcp-suite-core/files/etc/config/mptcp_suite
U=mptcp-suite-routing/files/etc/uci-defaults/98-mptcp-paused-failover
grep -Fq "option probe_ip_primary '1.1.1.1'" "$C"
grep -Fq "option probe_ip_secondary '8.8.8.8'" "$C"
grep -Fq 'set_default probe_ip_primary 1.1.1.1' "$U"
grep -Fq 'set_default probe_ip_secondary 8.8.8.8' "$U"
grep -Fq 'PROBE_IP_PRIMARY' "$M"
grep -Fq 'PROBE_IP_SECONDARY' "$M"
grep -Fq 'PROBE_IP_PRIMARY' "$R"
grep -Fq 'PROBE_IP_SECONDARY' "$R"
! grep -Fq 'mptcp_suite.failover.probe_ip)' "$M"
echo PAUSED_FAILOVER_DUAL_PROBE_V9_OK
