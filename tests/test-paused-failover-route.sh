#!/bin/sh
set -eu
R=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-route
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
cat >"$D/ip" <<'MOCK'
#!/bin/sh
echo "$*" >>"$LOG"
case "$*" in
 'route show default') printf '%b' "$SNAPSHOT";;
 'route get 8.8.8.8') echo "8.8.8.8 via ${EXPECT_GW:-192.168.1.1} dev ${EXPECT_DEV:-phy0-sta0}";;
 'route replace default via 192.168.1.1 dev phy0-sta0 metric 9') [ "${FAIL_SECONDARY_RESTORE:-0}" = 1 ] && exit 1;;
esac
exit 0
MOCK
cat >"$D/curl" <<'MOCK'
#!/bin/sh
echo "${HTTP:-204}"
MOCK
chmod 755 "$D/ip" "$D/curl"
run(){ env MPTCP_IP_BIN="$D/ip" MPTCP_CURL_BIN="$D/curl" MPTCP_PAUSED_FAILOVER_LOCK="$D/lock" MPTCP_PAUSED_FAILOVER_SNAP="$D/snap" MPTCP_PAUSED_FAILOVER_APPLY=1 LOG="$D/log" SNAPSHOT="$SNAPSHOT" EXPECT_GW="${EXPECT_GW:-192.168.1.1}" EXPECT_DEV="${EXPECT_DEV:-phy0-sta0}" HTTP="${HTTP:-204}" FAIL_SECONDARY_RESTORE="${FAIL_SECONDARY_RESTORE:-0}" "$R" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 url; }
SNAPSHOT='default via 192.168.8.1 dev eth1 proto static metric 7\ndefault via 192.168.1.1 dev phy0-sta0 proto static metric 9\n'; : >"$D/log"
run | grep -qx PAUSED_FAILOVER_ROUTE_OK=FAILOVER
grep -Fq 'route del default via 192.168.8.1 dev eth1 metric 7' "$D/log"
# Rollback parses proto static by keywords and restores both metrics
: >"$D/log"; set +e; O="$(HTTP=000 run 2>&1)"; RC=$?; set -e; [ "$RC" -eq 3 ]; echo "$O" | grep -Fq ERROR=http_validation_failed
grep -Fq 'route replace default via 192.168.8.1 dev eth1 metric 7' "$D/log"
grep -Fq 'route replace default via 192.168.1.1 dev phy0-sta0 metric 9' "$D/log"
# Variant without proto static also restores
SNAPSHOT='default via 192.168.8.1 dev eth1 metric 7\ndefault via 192.168.1.1 dev phy0-sta0 metric 9\n'; : >"$D/log"; set +e; HTTP=000 run >/dev/null 2>&1; RC=$?; set -e; [ "$RC" -eq 3 ]
# Invalid snapshot is rejected before any route deletion
SNAPSHOT='default via bad dev eth1 proto static metric 7\n'; : >"$D/log"; set +e; O="$(run 2>&1)"; RC=$?; set -e; [ "$RC" -eq 8 ]; echo "$O" | grep -Fq ERROR=invalid_snapshot
! grep -Fq 'route del default' "$D/log"
# Partial restore failure is surfaced
SNAPSHOT='default via 192.168.8.1 dev eth1 proto static metric 7\ndefault via 192.168.1.1 dev phy0-sta0 proto static metric 9\n'; : >"$D/log"; set +e; O="$(HTTP=000 FAIL_SECONDARY_RESTORE=1 run 2>&1)"; RC=$?; set -e; [ "$RC" -eq 7 ]; echo "$O" | grep -Fq ERROR=snapshot_restore_failed
echo PAUSED_FAILOVER_ROUTE_V4_OK
