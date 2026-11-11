#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-plan
[ "$(sh "$F" 3 3 primary)" = KEEP ]
[ "$(sh "$F" 0 2 primary)" = KEEP ]
[ "$(sh "$F" 0 3 primary)" = FAILOVER ]
[ "$(sh "$F" 2 3 secondary)" = KEEP ]
[ "$(sh "$F" 3 3 secondary)" = RESTORE ]
[ "$(sh "$F" 0 5 primary 5 4)" = FAILOVER ]
[ "$(sh "$F" 4 5 secondary 5 4)" = RESTORE ]
[ "$(sh "$F" 3 5 secondary 5 4)" = KEEP ]
! sh "$F" bad 3 primary >/dev/null 2>&1
! sh "$F" 0 3 bad 3 3 >/dev/null 2>&1
! sh "$F" 0 3 primary 0 3 >/dev/null 2>&1
echo FAILOVER_PLAN_OK
