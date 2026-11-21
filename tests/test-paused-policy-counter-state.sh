#!/bin/sh
set -eu
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
B="$(awk '/policy_cycle\(\)/,/^}/' "$M")"
printf '%s\n' "$B" | grep -Fq 'if [ "$PMODE" = primary ]; then'
printf '%s\n' "$B" | grep -Fq 'if [ "$PMODE" = secondary ]; then'
printf '%s\n' "$B" | grep -Fq 'SRC=0'
printf '%s\n' "$B" | grep -Fq 'SFC=0'
echo PAUSED_POLICY_COUNTER_STATE_V13_OK
