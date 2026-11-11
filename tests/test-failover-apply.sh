#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-apply
O="$(sh "$F" FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102)"
echo "$O" | grep -Fq 'table 102 metric 9'
O="$(sh "$F" RESTORE eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102)"
echo "$O" | grep -Fq 'table 102 metric 7'
[ "$(sh "$F" KEEP x x 1 x x 2 102)" = NO_CHANGE ]
! sh "$F" BAD x x 1 x x 2 102 >/dev/null 2>&1
echo FAILOVER_APPLY_DRYRUN_OK
