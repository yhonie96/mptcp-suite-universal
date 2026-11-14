#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-direct-restore}"
sh -n "$F"
grep -Fq DIRECT_RESTORE_DRY_RUN "$F"
grep -Fq DIRECT_RESTORE_OK "$F"
grep -Fq 'touch "$PAUSED"' "$F"
echo DIRECT_RESTORE_STRUCTURE_OK
