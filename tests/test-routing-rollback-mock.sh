#!/bin/sh
set -eu
R="${1:-./mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-rollback}"
D="${TMPDIR:-/tmp}/routing-rollback-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/config"
printf 'snapshot\n' >"$D/snapshot"
printf '1\n' >"$D/applied"
cat >"$D/bin/uci" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ]; do case "$1" in -c) shift 2;; -q) shift;; *) break;; esac; done
cmd="$1"; key="${2:-}"
case "$cmd:$key" in
 get:mptcp_suite.routing.primary_table) echo 11001;;
 get:mptcp_suite.routing.secondary_table) echo 11002;;
 get:mptcp_suite.routing.tproxy_table) echo 11003;;
 get:mptcp_suite.routing.primary_priority) echo 104;;
 get:mptcp_suite.routing.secondary_priority) echo 105;;
 get:mptcp_suite.routing.tproxy_priority) echo 106;;
 get:mptcp_suite.routing.applied) cat "$MOCK_APPLIED" 2>/dev/null;;
 set:mptcp_suite.routing.applied=0) [ "${MOCK_UCI_SET_FAIL:-0}" = 1 ] && exit 1; echo 0 >"$MOCK_APPLIED";;
 set:mptcp_suite.routing.applied=1) echo 1 >"$MOCK_APPLIED";;
 delete:mptcp_suite.routing.applied) rm -f "$MOCK_APPLIED";;
 commit:mptcp_suite) [ "${MOCK_UCI_COMMIT_FAIL:-0}" = 1 ] && exit 1;;
 *) exit 1;;
esac
exit 0
EOF
cat >"$D/bin/ip" <<'EOF'
#!/bin/sh
echo "IP $*" >>"$MOCK_LOG"
EOF
cat >"$D/bin/restore" <<'EOF'
#!/bin/sh
echo "RESTORE $*" >>"$MOCK_LOG"
[ "${MOCK_RESTORE_FAIL:-0}" = 1 ] && exit 1
exit 0
EOF
cat >"$D/bin/flock" <<'EOF'
#!/bin/sh
[ "${MOCK_LOCK_BUSY:-0}" = 1 ] && exit 1
exit 0
EOF
chmod 755 "$D/bin/"*
run(){
 env MOCK_APPLIED="$D/applied" MOCK_LOG="$D/actions" \
 MOCK_UCI_SET_FAIL="${MOCK_UCI_SET_FAIL:-0}" MOCK_UCI_COMMIT_FAIL="${MOCK_UCI_COMMIT_FAIL:-0}" \
 MOCK_RESTORE_FAIL="${MOCK_RESTORE_FAIL:-0}" MOCK_LOCK_BUSY="${MOCK_LOCK_BUSY:-0}" \
 MPTCP_ROUTING_SNAPSHOT="$D/snapshot" MPTCP_ROUTING_CONFIG_DIR="$D/config" \
 MPTCP_ROUTING_IP_BIN="$D/bin/ip" MPTCP_ROUTING_RESTORE_BIN="$D/bin/restore" MPTCP_ROUTING_UCI_BIN="$D/bin/uci" \
 MPTCP_ROUTING_FLOCK_BIN="$D/bin/flock" MPTCP_ROUTING_ROLLBACK_LOCK="$D/lock" "$R" "$@"
}

out="$(run --dry-run)"; echo "$out" | grep -Fq ROUTING_ROLLBACK_DRY_RUN
echo ROUTING_ROLLBACK_DRYRUN_OK
mv "$D/snapshot" "$D/snapshot.off"
set +e; out="$(run --apply 2>&1)"; rc=$?; set -e
[ "$rc" -eq 3 ]; echo "$out" | grep -Fq ERROR=snapshot_missing
mv "$D/snapshot.off" "$D/snapshot"
echo ROUTING_ROLLBACK_MISSING_SNAPSHOT_OK
: >"$D/actions"; echo 1 >"$D/applied"; run --apply | grep -Fq ROUTING_ROLLBACK_OK
[ "$(cat "$D/applied")" = 0 ]; grep -Fq '11001 11002 11003 104 105 106' "$D/actions"
grep -Fq 'IP rule del priority 104' "$D/actions"
grep -Fq 'IP rule del priority 105' "$D/actions"
grep -Fq 'IP rule del priority 106' "$D/actions"
grep -Fq 'IP route flush table 11001' "$D/actions"
grep -Fq 'IP route flush table 11002' "$D/actions"
grep -Fq 'IP route flush table 11003' "$D/actions"
echo ROUTING_ROLLBACK_SUCCESS_OK
echo 1 >"$D/applied"; set +e; out="$(MOCK_RESTORE_FAIL=1 run --apply 2>&1)"; rc=$?; set -e
[ "$rc" -eq 7 ]; [ "$(cat "$D/applied")" = 1 ]; echo "$out" | grep -Fq ERROR=restore_failed
echo ROUTING_ROLLBACK_RESTORE_FAIL_OK
echo 1 >"$D/applied"; set +e; out="$(MOCK_UCI_SET_FAIL=1 run --apply 2>&1)"; rc=$?; set -e
[ "$rc" -eq 8 ]; [ "$(cat "$D/applied")" = 1 ]
echo ROUTING_ROLLBACK_UCI_SET_FAIL_OK
echo 1 >"$D/applied"; set +e; out="$(MOCK_UCI_COMMIT_FAIL=1 run --apply 2>&1)"; rc=$?; set -e
[ "$rc" -eq 10 ]; [ "$(cat "$D/applied")" = 1 ]
echo ROUTING_ROLLBACK_UCI_COMMIT_FAIL_OK
set +e; out="$(MOCK_LOCK_BUSY=1 run --apply 2>&1)"; rc=$?; set -e
[ "$rc" -eq 5 ]; echo "$out" | grep -Fq ERROR=lock_busy
echo ROUTING_ROLLBACK_LOCK_BUSY_OK
