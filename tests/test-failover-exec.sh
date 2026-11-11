#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-exec
grep -Fq 'MODE="${1:---dry-run}"' "$F"
grep -Fq 'ERROR=apply_not_enabled' "$F"
grep -Fq 'exec "$APPLY"' "$F"
! sh "$F" --apply FAILOVER x x 7 y y 9 102 >/dev/null 2>&1
! sh "$F" --bad >/dev/null 2>&1
echo FAILOVER_EXEC_SAFE_DEFAULT_OK
