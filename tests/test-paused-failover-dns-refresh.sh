#!/bin/sh
set -eu
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
P=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-policy-failover
C=mptcp-suite-dual-xray/files/etc/xray-dns/config.json
sh -n "$M" "$P"
! grep -Fq '"skipFallback": true' "$C"
[ "$(jq '.dns.servers | length' "$C")" -ge 2 ]
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
cat >"$D/uci" <<'MOCK'
#!/bin/sh
case "$*" in
 *failover.enabled) echo 1;;
 *primary_interface|*secondary_interface) exit 1;;
 *core.primary_wan) echo uplink_a;;
 *core.secondary_wan) echo uplink_b;;
 *failure_threshold|*recovery_threshold) echo 2;;
 *failover.interval) echo 1;;
 *check_url) echo url;;
 *probe_ip_primary) echo 1.1.1.1;;
 *probe_ip_secondary) echo 8.8.8.8;;
 *uplink_a.device) echo eth1;;
 *uplink_a.gateway) echo 192.168.8.1;;
 *uplink_a.metric) echo 7;;
 *uplink_b.device) echo phy0-sta0;;
 *uplink_b.gateway) echo 192.168.1.1;;
 *uplink_b.metric) echo 9;;
esac
MOCK
cat >"$D/ping" <<'MOCK'
#!/bin/sh
case "$*" in
 *eth1*) [ "${PICMP:-204}" = 204 ];;
 *phy0-sta0*) [ "${SICMP:-204}" = 204 ];;
 *) exit 1;;
esac
MOCK
cat >"$D/curl" <<'MOCK'
#!/bin/sh
case "$*" in
 *eth1*) printf "%s" "${PHTTP:-204}";;
 *phy0-sta0*) printf "%s" "${SHTTP:-204}";;
 *) printf 000;;
esac
MOCK
cat >"$D/ip" <<'MOCK'
#!/bin/sh
case "$*" in
 "route get 8.8.8.8")
  case "$(cat "$MODE_FILE")" in
   primary) echo '8.8.8.8 via 192.168.8.1 dev eth1';;
   secondary) echo '8.8.8.8 via 192.168.1.1 dev phy0-sta0';;
  esac
 ;;
 "route show table 101")
  echo 'default via 192.168.1.1 dev phy0-sta0 proto static metric 9'
 ;;
esac
MOCK
cat >"$D/route" <<'MOCK'
#!/bin/sh
case "$2" in
 FAILOVER) echo secondary >"$MODE_FILE";;
 RESTORE) echo primary >"$MODE_FILE";;
esac
MOCK
cat >"$D/xray-dns" <<'MOCK'
#!/bin/sh
echo "xray-dns $*" >>"$SVC_LOG"
MOCK
cat >"$D/dnsmasq" <<'MOCK'
#!/bin/sh
echo "dnsmasq $*" >>"$SVC_LOG"
MOCK
chmod 755 "$D/"*
echo primary >"$D/mode"; touch "$D/paused"; : >"$D/svc.log"
run(){
 env MPTCP_UCI_BIN="$D/uci" \
  MPTCP_PING_BIN="$D/ping" \
  MPTCP_CURL_BIN="$D/curl" \
  MPTCP_IP_BIN="$D/ip" \
  MPTCP_PAUSED_FAILOVER_ROUTE_BIN="$D/route" \
  MPTCP_XRAY_DNS_SERVICE="$D/xray-dns" \
  MPTCP_DNSMASQ_SERVICE="$D/dnsmasq" \
  MPTCP_PAUSED_FILE="$D/paused" \
  MPTCP_PAUSED_FAILOVER_STATE="$D/state" \
  MPTCP_PAUSED_POLICY_STATE="$D/policy-state" \
  MPTCP_PAUSED_FAILOVER_MONITOR_LOCK="$D/monitor.lock" \
  MPTCP_PAUSED_FAILOVER_ONCE=1 \
  MODE_FILE="$D/mode" \
  SVC_LOG="$D/svc.log" \
  PHTTP="${PHTTP:-204}" \
  SHTTP="${SHTTP:-204}" \
  PICMP="${PICMP:-${PHTTP:-204}}" \
  SICMP="${SICMP:-${SHTTP:-204}}" \
  "$M" --run >/dev/null
}
PHTTP=000 run
[ ! -s "$D/svc.log" ]
PHTTP=204 run
grep -qx 'xray-dns restart' "$D/svc.log"
grep -qx 'dnsmasq restart' "$D/svc.log"
: >"$D/svc.log"; PHTTP=000 run; PHTTP=000 run
[ "$(cat "$D/mode")" = secondary ]
grep -qx 'xray-dns restart' "$D/svc.log"
: >"$D/svc.log"; PHTTP=204 run; PHTTP=204 run
[ "$(cat "$D/mode")" = primary ]
grep -qx 'xray-dns restart' "$D/svc.log"
echo PAUSED_FAILOVER_DNS_REFRESH_OK
