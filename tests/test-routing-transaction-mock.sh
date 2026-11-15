#!/bin/sh
set -eu
E=mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-exec
D="$(mktemp -d)"
trap 'rm -rf "$D" /tmp/mptcp-routing.lock /tmp/mptcp-routing.snapshot' EXIT
mkdir "$D/bin" "$D/cfg"
LOG="$D/log"; export LOG
P="$D/plan"; S="$D/snap"
cat >"$D/bin/uci" <<'MOCK'
#!/bin/sh
for X do :; done
case "$X" in
*.allocated) echo 1;;
*.primary_table) echo 11001;;
*.secondary_table) echo 11002;;
*.tproxy_table) echo 11003;;
*.primary_priority) echo 98;;
*.secondary_priority) echo 99;;
*.tproxy_priority) echo 100;;
*.bypass_mark) echo 0x4A02;;
*.policy_mark) echo 0x4A03;;
*.tproxy_mark) echo 0x4A01;;
esac
MOCK
chmod 755 "$D/bin/uci"
export PATH="$D/bin:$PATH"
cat >"$D/plan" <<'MOCK'
#!/bin/sh
echo "ip route replace local 0.0.0.0/0 dev lo table 11003" >"$2"
echo "ip rule add priority 98 fwmark 0x4A02 lookup 11001" >>"$2"
echo "ip rule add priority 99 fwmark 0x4A03 lookup 11002" >>"$2"
echo "ip rule add priority 100 fwmark 0x4A01 lookup 11003" >>"$2"
MOCK
chmod 755 "$D/plan"
"$D/plan" "$D/cfg" "$P"
cp tests/mock-routing-ip.sh "$D/bin/ip"
chmod 755 "$D/bin/ip"
: >"$LOG"
MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-transaction >"$D/out"
grep -Fq ROUTING_APPLY_OK "$D/out"
grep -Fq "route show table 11001" "$LOG"
grep -Fq "route get 8.8.8.8 mark 0x4A01" "$LOG"
! grep -Eq "[[:space:]]$" /tmp/mptcp-routing.snapshot
DL="$(grep -n "rule del priority 98" "$LOG" | head -n1 | cut -d: -f1)"
AL="$(grep -n "rule add priority 98" "$LOG" | head -n1 | cut -d: -f1)"
[ -n "$DL" ] && [ -n "$AL" ] && [ "$DL" -lt "$AL" ]
echo ROUTING_TRANSACTION_SUCCESS_OK
: >"$LOG"
printf '#!/bin/sh
echo RESTORE_CALLED >>"$LOG"
exit 0
' >"$D/restore"
chmod 755 "$D/restore"
export MOCK_IP_FAIL="route replace local 0.0.0.0/0 dev lo table 11003"
set +e
OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" MPTCP_ROUTING_RESTORE_BIN="$D/restore" "$E" --test-transaction 2>&1)"
RC=$?
set -e
unset MOCK_IP_FAIL
[ "$RC" -eq 11 ]
[ "$OUT" = ERROR=plan_apply_failed_snapshot_restored ]
grep -Fq RESTORE_CALLED "$LOG"
echo ROUTING_TRANSACTION_ROLLBACK_PATH_OK
: >"$LOG"
export MOCK_IP_FAIL="route replace local 0.0.0.0/0 dev lo table 11003"
printf '#!/bin/sh\nexit 1\n' >"$D/restore-fail"
chmod 755 "$D/restore-fail"
set +e
MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" MPTCP_ROUTING_RESTORE_BIN="$D/restore-fail" "$E" --test-transaction >/dev/null 2>&1
RC=$?
set -e; unset MOCK_IP_FAIL
[ "$RC" -eq 13 ]
echo ROUTING_TRANSACTION_RESTORE_FAILURE_OK
: >"$LOG"; export MOCK_BAD_ROUTE=1
set +e; OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" MPTCP_ROUTING_RESTORE_BIN="$D/restore" "$E" --test-transaction 2>&1)"; RC=$?; set -e; unset MOCK_BAD_ROUTE
[ "$RC" -eq 12 ]; [ "$OUT" = ERROR=validation_failed_snapshot_restored ]; grep -Fq RESTORE_CALLED "$LOG"
echo ROUTING_TRANSACTION_VALIDATION_ROLLBACK_OK
: >"$LOG"; rm -f /tmp/mptcp-routing.snapshot
export MOCK_IP_FAIL="route show table 11002"
set +e; OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-transaction 2>&1)"; RC=$?; set -e; unset MOCK_IP_FAIL
[ "$RC" -eq 14 ]
[ "$OUT" = ERROR=snapshot_failed ]
test ! -e /tmp/mptcp-routing.snapshot
! grep -Fq "route replace" "$LOG"
! grep -Fq "rule del priority" "$LOG"
echo ROUTING_TRANSACTION_SNAPSHOT_FAILURE_OK
: >"$LOG"
export MOCK_IP_MISSING="route show table 11002"
set +e
OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-transaction 2>&1)"
RC=$?
set -e
unset MOCK_IP_MISSING
[ "$RC" -eq 0 ]
[ "$OUT" = ROUTING_APPLY_OK ]
echo ROUTING_TRANSACTION_EMPTY_TABLE_OK
