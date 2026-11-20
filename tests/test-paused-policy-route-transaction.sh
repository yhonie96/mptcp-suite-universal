#!/bin/sh
set -eu
H=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-policy-failover
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin"; touch "$D/paused"; printf 'default via 192.168.1.1 dev phy0-sta0 metric 9\n' >"$D/table"
cat >"$D/bin/uci" <<'E'
#!/bin/sh
case "$*" in *core.primary_wan) echo WAN1;; *core.secondary_wan) echo wwan;; *WAN1.device) echo eth1;; *WAN1.gateway) echo 192.168.8.1;; *WAN1.metric) echo 7;; *wwan.device) echo phy0-sta0;; *wwan.gateway) echo 192.168.1.1;; *wwan.metric) echo 9;; *) exit 1;; esac
E
cat >"$D/bin/flock" <<'E'
#!/bin/sh
[ "${LOCK_BUSY:-0}" = 1 ] && exit 1; exit 0
E
cat >"$D/bin/ip" <<'E'
#!/bin/sh
echo "$*" >>"$LOG"
case "$*" in
 "route show table 101") cat "$MOCK_TABLE";;
 "route flush table 101") : >"$MOCK_TABLE";;
 "route add default via "*) [ "${ADD_FAIL:-0}" = 1 ] && echo "$*" | grep -q "dev eth1" && exit 1; echo "default via $5 dev $7 metric ${11}" >"$MOCK_TABLE";;
 "rule del priority 99") exit 0;;
 "rule add priority 99 fwmark 0x102/0x1ff lookup 101") exit 0;;
 "route flush cache") exit 0;;
 *) exit 1;;
esac
E
chmod 755 "$D/bin/"*
run(){ env MOCK_TABLE="$D/table" LOG="$D/log" LOCK_BUSY="${LOCK_BUSY:-0}" ADD_FAIL="${ADD_FAIL:-0}" MPTCP_UCI_BIN="$D/bin/uci" MPTCP_IP_BIN="$D/bin/ip" MPTCP_FLOCK_BIN="$D/bin/flock" MPTCP_PAUSED_FILE="$D/paused" MPTCP_POLICY_LOCK="$D/lock" MPTCP_POLICY_SNAPSHOT="$D/snap" "$H" "$@"; }
run --primary-fallback | grep -qx PAUSED_POLICY_ROUTE_OK=PRIMARY_FALLBACK
grep -qx 'default via 192.168.8.1 dev eth1 metric 7' "$D/table"; [ "$(grep -c '^default ' "$D/table")" -eq 1 ]
run --secondary | grep -qx PAUSED_POLICY_ROUTE_OK=SECONDARY
grep -qx 'default via 192.168.1.1 dev phy0-sta0 metric 9' "$D/table"; [ "$(grep -c '^default ' "$D/table")" -eq 1 ]
set +e; O="$(ADD_FAIL=1 run --primary-fallback 2>&1)"; R=$?; set -e
[ "$R" -eq 6 ]; echo "$O" | grep -qx ERROR=transaction_failed; grep -qx 'default via 192.168.1.1 dev phy0-sta0 metric 9' "$D/table"
set +e; O="$(LOCK_BUSY=1 run --secondary 2>&1)"; R=$?; set -e
[ "$R" -eq 5 ]; echo "$O" | grep -qx ERROR=lock_busy
echo PAUSED_POLICY_ROUTE_TRANSACTION_V11_OK
# Runtime iproute2 may append whitespace or protocol tokens; verification must parse required tokens.
printf 'default via 192.168.1.1 dev phy0-sta0 metric 9 \n' >"$D/table"
run --primary-fallback | grep -qx PAUSED_POLICY_ROUTE_OK=PRIMARY_FALLBACK
grep -qx 'default via 192.168.8.1 dev eth1 metric 7' "$D/table"
echo PAUSED_POLICY_ROUTE_FORMAT_V12_OK
