#!/bin/sh
set -eu
C=mptcp-suite-core/files/etc/config/mptcp_suite
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
U=mptcp-suite-routing/files/etc/uci-defaults/98-mptcp-paused-failover
! grep -Eq 'WAN1|wwan' "$C" "$M" "$U"
grep -Fq 'mptcp_suite.core.primary_wan' "$M"
grep -Fq 'mptcp_suite.core.secondary_wan' "$M"
grep -Fq 'set_default interval 10' "$U"
! grep -Fq 'set_default primary_interface' "$U"
! grep -Fq 'set_default secondary_interface' "$U"
echo PAUSED_FAILOVER_UNIVERSAL_V6_OK
