#!/bin/sh
set -eu
D_BIN=./luci-app-mptcp-suite/files/usr/sbin/mptcp-endpoint-daemon
D_INIT=./luci-app-mptcp-suite/files/etc/init.d/mptcp-endpoint-daemon
sh -n "$D_BIN" "$D_INIT"
test -x "$D_BIN" -a -x "$D_INIT"
grep -Fq 'paused' "$D_INIT"
! grep -Eq 'fping|mptcpize|bsbf-mptcp-helper' "$D_BIN"

T="${TMPDIR:-/tmp}/mptcp-ep-test-$$"
trap 'rm -rf "$T"' EXIT INT TERM
mkdir -p "$T/conf" "$T/run" "$T/bin"

cat >"$T/bin/ip" <<'MOCK'
#!/bin/sh
echo "ip $*" >>"$MOCK_LOG"
case "$1 $2" in
 "-4 route") printf '%s\n' "${MOCK_ROUTES:-}" ;;
 "-4 -o")
  case "$6" in
   eth1) printf '2: eth1 inet %s/24 scope global eth1\n' "${MOCK_ETH1_IP:-10.0.1.10}" ;;
   wwan0) printf '3: wwan0 inet %s/24 scope global wwan0\n' "${MOCK_WWAN_IP:-10.0.2.20}" ;;
  esac ;;
 "mptcp endpoint") [ "${3:-}" = "show" ] && printf '%s\n' "${MOCK_EP_SHOW:-}" ;;
esac
MOCK
printf '#!/bin/sh\necho "ping $*" >>"$MOCK_LOG"\n[ "${MOCK_PING_FAIL:-}" = "$2" ] && exit 1\nexit 0\n' >"$T/bin/ping"
printf '#!/bin/sh\necho "sysctl $*" >>"$MOCK_LOG"\n' >"$T/bin/sysctl"
printf '#!/bin/sh\nexit 1\n' >"$T/bin/uci"
chmod 755 "$T/bin/ip" "$T/bin/ping" "$T/bin/sysctl" "$T/bin/uci"

run_once() {
 env MOCK_LOG="$T/log" MOCK_ROUTES="${MOCK_ROUTES:-}" MOCK_ETH1_IP="${MOCK_ETH1_IP:-10.0.1.10}" \
  MOCK_WWAN_IP="${MOCK_WWAN_IP:-10.0.2.20}" MOCK_EP_SHOW="${MOCK_EP_SHOW:-}" MOCK_PING_FAIL="${MOCK_PING_FAIL:-}" \
  MPTCP_SUITE_DIR="$T/conf" MPTCP_RUN_DIR="$T/run" MPTCP_PAUSED_FILE="$T/conf/paused" \
  MPTCP_IP_BIN="$T/bin/ip" MPTCP_PING_BIN="$T/bin/ping" MPTCP_SYSCTL_BIN="$T/bin/sysctl" MPTCP_UCI_BIN="$T/bin/uci" \
  MPTCP_KERNEL_ENABLED=1 "$D_BIN" --once
}
: >"$T/log"; touch "$T/conf/paused"
MOCK_ROUTES="default via 10.0.1.1 dev eth1 metric 10" run_once
[ ! -s "$T/log" ]

rm -f "$T/conf/paused" "$T/run/"*; : >"$T/log"
printf 'wwan0\n' >"$T/conf/mptcp-subflow-backup"
MOCK_ROUTES="$(printf 'default via 10.0.1.1 dev eth1 metric 10\ndefault via 10.0.2.1 dev wwan0 metric 11')" \
 MOCK_EP_SHOW="$(printf '10.0.1.10 id 1 subflow dev eth1\n10.0.2.20 id 2 subflow dev wwan0')" run_once
grep -qx 'eth1' "$T/run/endpoints-supported"
grep -qx 'wwan0' "$T/run/endpoints-supported"
grep -Fq 'ip mptcp endpoint change id 1 nobackup' "$T/log"
grep -Fq 'ip mptcp endpoint change id 2 backup' "$T/log"

: >"$T/log"
MOCK_ROUTES="default via 10.0.1.1 dev eth1 metric 10" MOCK_ETH1_IP="10.0.1.99" \
 MOCK_EP_SHOW="10.0.1.10 id 1 subflow dev eth1" run_once
grep -Fq 'ip mptcp endpoint delete id 1' "$T/log"
grep -Fq 'ip mptcp endpoint add 10.0.1.99 subflow dev eth1' "$T/log"

: >"$T/log"
MOCK_ROUTES="$(printf 'default via 10.0.1.1 dev eth1 metric 10\ndefault via 10.0.2.1 dev wwan0 metric 11')" \
 MOCK_PING_FAIL="eth1" MOCK_EP_SHOW="10.0.1.99 id 1 subflow dev eth1" run_once
grep -qx 'eth1' "$T/run/endpoints-no-connectivity"
grep -Fq 'ip route add default via 10.0.1.1 dev eth1 metric 12' "$T/log"
echo ENDPOINT_DAEMON_ALL_OK
