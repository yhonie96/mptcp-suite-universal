#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-exec

grep -Fq 'MODE="${1:---dry-run}"' "$F"
grep -Fq 'exec "$APPLY"' "$F"
grep -Fq 'flock -n 9' "$F"
grep -Fq 'snapshot "$@"' "$F"
grep -Fq 'APPLY_OK=$ACTION' "$F"
grep -Fq 'ERROR=validation_failed' "$F"

! grep -Fq 'ERROR=apply_not_enabled' "$F"
! sh "$F" --bad >/dev/null 2>&1

echo FAILOVER_EXEC_STRUCTURE_OK
