#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-exec
grep -Fq 'APPLY_OK=$ACTION' "$F"
grep -Fq 'ERROR=validation_failed' "$F"
grep -Fq 'curl --interface "$TARGET"' "$F"
grep -Fq 'snapshot "$@"' "$F"
echo FAILOVER_TRANSACTION_STRUCTURE_OK
grep -Fq 'ERROR=apply_locked' "$F"
grep -Fq 'ROLLBACK=RESTORE' "$F"
grep -Fq 'ROLLBACK=FAILOVER' "$F"
grep -Fq 'validation_failed_rollback_done' "$F"
grep -Fq 'MPTCP_FAILOVER_APPLY_BIN' "$F"
grep -Fq 'TARGET="${5:-}"' "$F"
grep -Fq 'TARGET="${2:-}"' "$F"
