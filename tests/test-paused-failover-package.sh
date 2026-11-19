#!/bin/sh
set -eu
grep -Fq 'mptcp-paused-failover' mptcp-suite-routing/Makefile
grep -Fq 'USE_PROCD=1' mptcp-suite-routing/files/etc/init.d/mptcp-paused-failover
grep -Fq 'stop_service()' mptcp-suite-routing/files/etc/init.d/mptcp-paused-failover
grep -Fq -- '--restore' mptcp-suite-routing/files/etc/init.d/mptcp-paused-failover
grep -Fq "option primary_interface 'WAN1'" mptcp-suite-core/files/etc/config/mptcp_suite
grep -Fq "option secondary_interface 'wwan'" mptcp-suite-core/files/etc/config/mptcp_suite
! grep -Fq '. "$STATE"' mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
grep -Fq 'mv "$T" "$STATE"' mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
echo PAUSED_FAILOVER_PACKAGE_V2_OK
grep -Fq '98-mptcp-paused-failover' mptcp-suite-routing/Makefile
grep -Fq 'set_default primary_interface WAN1' mptcp-suite-routing/files/etc/uci-defaults/98-mptcp-paused-failover
grep -Fq 'set_default secondary_interface wwan' mptcp-suite-routing/files/etc/uci-defaults/98-mptcp-paused-failover
grep -Fq 'set_default interval 10' mptcp-suite-routing/files/etc/uci-defaults/98-mptcp-paused-failover
