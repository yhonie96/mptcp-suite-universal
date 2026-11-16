#!/bin/sh
set -eu
H=mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-managed-clear
D="$(mktemp -d)"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/cfg" "$D/state"
cat >"$D/bin/uci" <<'MOCK'
#!/bin/sh
while [ "$#" -gt 0 ]; do case "$1" in -c) shift 2;; -q) shift;; *) break;; esac; done
case "$1:$2" in
 get:mptcp_suite.routing.primary_table) echo 11001;;
 get:mptcp_suite.routing.secondary_table) echo 11002;;
 get:mptcp_suite.routing.tproxy_table) echo 11003;;
 get:mptcp_suite.routing.primary_priority) echo 104;;
 get:mptcp_suite.routing.secondary_priority) echo 105;;
 get:mptcp_suite.routing.tproxy_priority) echo 106;;
 get:mptcp_suite.routing.applied) cat "$MOCK_STATE/applied";;
 set:mptcp_suite.routing.applied=0) echo 0 >"$MOCK_STATE/applied";;
 set:mptcp_suite.routing.applied=1) echo 1 >"$MOCK_STATE/applied";;
 commit:mptcp_suite) [ "${MOCK_COMMIT_FAIL:-0}" = 1 ] && exit 1 || exit 0;;
 *) exit 1;;
esac
MOCK
cat >"$D/bin/flock" <<'MOCK'
#!/bin/sh
[ "${MOCK_LOCK_BUSY:-0}" = 1 ] && exit 1
exit 0
MOCK
cat >"$D/bin/ip" <<'MOCK'
#!/bin/sh
echo "$*" >>"$MOCK_LOG"
case "$*" in
 "rule show") cat "$MOCK_STATE/rules" 2>/dev/null || true;;
 "rule del priority "*) P="$4"; grep -v "^$P:" "$MOCK_STATE/rules" >"$MOCK_STATE/rules.new" || true; mv "$MOCK_STATE/rules.new" "$MOCK_STATE/rules";;
 "rule add priority "*) echo "$4: from all fwmark $6 lookup $8" >>"$MOCK_STATE/rules";;
 "route show table "*) cat "$MOCK_STATE/table.$4" 2>/dev/null || true;;
 "route flush table "*) rm -f "$MOCK_STATE/table.$4";;
 "route replace default via "*) T="$9"; if [ "$#" -eq 11 ]; then echo "default via $5 dev $7 metric $11"; else echo "default via $5 dev $7"; fi >"$MOCK_STATE/table.$T";;
 "route replace local 0.0.0.0/0 dev lo table "*) echo "local default dev lo scope host" >"$MOCK_STATE/table.$8";;
 *) exit 1;;
esac
MOCK
chmod 755 "$D/bin/"*
reset(){
 echo 1 >"$D/state/applied"
 printf '98: from all fwmark 0x2 lookup 102\n104: from all fwmark 0x4a04 lookup 11001\n105: from all fwmark 0x4a06 lookup 11002\n106: from all fwmark 0x4a02 lookup 11003\n5210: from all fwmark 0x80000/0xff0000 lookup main\n' >"$D/state/rules"
 echo 'default via 10.0.0.1 dev eth9' >"$D/state/table.11001"
 echo 'default via 20.0.0.1 dev wlan9' >"$D/state/table.11002"
 echo 'local default dev lo scope host' >"$D/state/table.11003"
 : >"$D/log"
}
run(){ env MOCK_STATE="$D/state" MOCK_LOG="$D/log" MOCK_COMMIT_FAIL="${MOCK_COMMIT_FAIL:-0}" MOCK_LOCK_BUSY="${MOCK_LOCK_BUSY:-0}" MPTCP_ROUTING_IP_BIN="$D/bin/ip" MPTCP_ROUTING_UCI_BIN="$D/bin/uci" MPTCP_ROUTING_FLOCK_BIN="$D/bin/flock" MPTCP_ROUTING_CONFIG_DIR="$D/cfg" MPTCP_ROUTING_CLEAR_LOCK="$D/lock" MPTCP_ROUTING_CLEAR_STATE="$D/clear.state" "$H" "$@"; }
run --dry-run | grep -qx ROUTING_MANAGED_CLEAR_DRY_RUN
set +e; O="$(run --apply 2>&1)"; R=$?; set -e
[ "$R" -eq 3 ]; printf "%s\n" "$O" | grep -qx ERROR=apply_locked
reset
O="$(MPTCP_ROUTING_CLEAR_APPLY=1 run --apply)"; [ "$O" = ROUTING_MANAGED_CLEAR_OK ]
[ "$(cat "$D/state/applied")" = 0 ]
grep -q '^98:' "$D/state/rules"; grep -q '^5210:' "$D/state/rules"
! grep -Eq '^(104|105|106):' "$D/state/rules"
for T in 11001 11002 11003; do [ ! -e "$D/state/table.$T" ]; done
reset
set +e; O="$(MOCK_COMMIT_FAIL=1 MPTCP_ROUTING_CLEAR_APPLY=1 run --apply 2>&1)"; R=$?; set -e
[ "$R" -eq 9 ]; printf "%s\n" "$O" | grep -qx ERROR=state_commit_failed
[ "$(cat "$D/state/applied")" = 1 ]
for P in 98 104 105 106 5210; do grep -q "^$P:" "$D/state/rules"; done
for T in 11001 11002 11003; do test -s "$D/state/table.$T"; done
reset
set +e; O="$(MOCK_LOCK_BUSY=1 MPTCP_ROUTING_CLEAR_APPLY=1 run --apply 2>&1)"; R=$?; set -e
[ "$R" -eq 5 ]; printf "%s\n" "$O" | grep -qx ERROR=lock_busy
echo ROUTING_MANAGED_CLEAR_TEST_OK
