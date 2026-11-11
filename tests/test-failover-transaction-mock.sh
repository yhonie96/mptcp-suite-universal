#!/bin/sh
set -eu
E=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-exec
D="$(mktemp -d)"
trap 'rm -rf "$D" /tmp/mptcp-failover.lock /tmp/mptcp-failover.routes' EXIT
mkdir -p "$D/bin"

cat >"$D/apply" <<'MOCK'
#!/bin/sh
echo "$1" >>"$MOCK_ACTIONS"
case "$1" in
 FAILOVER) echo "ip route replace default via 192.168.1.1 dev phy0-sta0 table 102 metric 9" ;;
 RESTORE)
  [ "${MOCK_ROLLBACK_FAIL:-0}" = 1 ] && exit 1
  echo "ip route replace default via 192.168.8.1 dev eth1 table 102 metric 7"
 ;;
esac
MOCK

cat >"$D/bin/ip" <<'MOCK'
#!/bin/sh
echo "$*" >>"$MOCK_EXEC"
case "$*" in
 "route show"*) echo "default via 192.168.8.1 dev eth1 metric 7" ;;
 "route get 8.8.8.8 mark 0x2") echo "${MOCK_MARK_ROUTE:-8.8.8.8 via 192.168.1.1 dev phy0-sta0 table 102 mark 2}" ;;
esac
MOCK

cat >"$D/bin/curl" <<'MOCK'
#!/bin/sh
echo "${MOCK_HTTP:-204}"
MOCK

chmod 755 "$D/apply" "$D/bin/"*
export MOCK_ACTIONS="$D/actions"
export MOCK_EXEC="$D/executed"
export MPTCP_FAILOVER_APPLY=1
export MPTCP_FAILOVER_APPLY_BIN="$D/apply"
REAL_RESTORE="$PWD/mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-restore"
cat >"$D/restore" <<'MOCK'
#!/bin/sh
[ "${MOCK_RESTORE_FAIL:-0}" = 1 ] && exit 1
exec "$REAL_RESTORE" "$@"
MOCK
chmod 755 "$D/restore"
export REAL_RESTORE
export MPTCP_FAILOVER_RESTORE_BIN="$D/restore"
export PATH="$D/bin:$PATH"

MOCK_HTTP=204 sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102
grep -qx FAILOVER "$MOCK_ACTIONS"
grep -Fq "route replace default via 192.168.1.1" "$MOCK_EXEC"

: >"$MOCK_ACTIONS"
: >"$MOCK_EXEC"
export MOCK_HTTP=000
if OUT="$(sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102 2>&1)"; then
 echo "ERROR=expected_validation_failure"; exit 1
fi
printf '%s
' "$OUT"
grep -Fq "ERROR=validation_failed_snapshot_restored" <<EOF
$OUT
EOF
grep -qx FAILOVER "$MOCK_ACTIONS"
grep -qx RESTORE "$MOCK_ACTIONS"
grep -Fq "route replace default via 192.168.8.1" "$MOCK_EXEC"

export MOCK_ROLLBACK_FAIL=1
set +e
OUT="$(sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102 2>&1)"
RC=$?
set -e
[ "$RC" -eq 6 ]
echo "$OUT" | grep -Fq "ERROR=rollback_action_failed"
unset MOCK_ROLLBACK_FAIL

export MOCK_RESTORE_FAIL=1
set +e
OUT="$(sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102 2>&1)"
RC=$?
set -e
[ "$RC" -eq 7 ]
echo "$OUT" | grep -Fq "ERROR=snapshot_restore_failed"
unset MOCK_RESTORE_FAIL

export MOCK_HTTP=204
export MOCK_MARK_ROUTE="8.8.8.8 via 192.168.8.1 dev eth1 table 102 mark 2"
set +e
OUT="$(sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102 2>&1)"
RC=$?
set -e
[ "$RC" -eq 3 ]
echo "$OUT" | grep -Fq "ERROR=validation_failed_snapshot_restored"
unset MOCK_MARK_ROUTE
echo FAILOVER_MARK_VALIDATION_OK

echo FAILOVER_TRANSACTION_NEGATIVE_OK
echo FAILOVER_TRANSACTION_MOCK_OK
