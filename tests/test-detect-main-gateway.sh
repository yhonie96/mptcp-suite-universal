#!/bin/sh
set -eu
F=mptcp-suite-core/files/usr/libexec/mptcp-suite/detect
grep -Fq MPTCP_MAIN_GATEWAY_BIN "$F"
grep -Fq '"$GATEWAY"' "$F"
! grep -Fq "route[0].nexthop" "$F"
[ "$(grep -c "ifstatus.*\$s" "$F")" -eq 1 ]
echo DETECT_MAIN_GATEWAY_STRUCTURE_OK
