#!/bin/sh
set -eu
SRC="$PWD/mptcp-suite-traffic/files/usr/libexec/mptcp-suite/traffic-plan"
D="$(mktemp -d)"
trap 'rm -rf "$D"' EXIT
mkdir -p "$D/bin"

cat >"$D/bin/uci" <<'MOCK'
#!/bin/sh
for LAST do :; done
case "$*" in
*" show mptcp_suite")
 echo mptcp_suite.phone=traffic_rule
 exit 0
 ;;
esac
case "$LAST" in
*mptcp_suite.routing.tproxy_mark) echo "${TM:-0x4A01}";;
*mptcp_suite.routing.bypass_mark) echo "${BM:-0x4A02}";;
*mptcp_suite.routing.policy_mark) echo "${PM:-0x4A03}";;
*mptcp_suite.phone.enabled) echo "${ENABLED:-1}";;
*mptcp_suite.phone.policy) echo "${POLICY:-secondary}";;
*mptcp_suite.phone.src_ip) echo "${IP-192.0.2.20/32}";;
*mptcp_suite.phone.src_mac) echo "${MAC-AA:BB:CC:DD:EE:01}";;
esac
MOCK

chmod 755 "$D/bin/uci"
PATH="$D/bin:$PATH"
export PATH

sh "$SRC" "$D" "$D/ok.nft" >/dev/null
grep -q 'fib daddr type local return' "$D/ok.nft"
grep -q 'udp dport 53 return' "$D/ok.nft"
grep -q '192.0.2.20/32 meta mark set 0x4A03 return' "$D/ok.nft"
grep -q 'AA:BB:CC:DD:EE:01 meta mark set 0x4A03 return' "$D/ok.nft"
for CASE in bypass primary secondary tproxy; do
 POLICY="$CASE"; export POLICY
 sh "$SRC" "$D" "$D/$CASE.nft" >/dev/null || exit 1
done
grep -q "ip saddr 192.0.2.20/32 return" "$D/bypass.nft"
grep -q "ip saddr 192.0.2.20/32 meta mark set 0x4A02 return" "$D/primary.nft"
grep -q "ip saddr 192.0.2.20/32 meta mark set 0x4A03 return" "$D/secondary.nft"
grep -q "ip saddr 192.0.2.20/32 meta mark set 0x4A01 return" "$D/tproxy.nft"
POLICY=secondary; export POLICY
if [ "${NFT_CHECK:-0}" = 1 ]; then
 for F in ok bypass primary secondary tproxy; do
  nft --check --file "$D/$F.nft" || exit 1
 done
fi

POLICY=invalid
export POLICY
! sh "$SRC" "$D" "$D/policy.nft" >/dev/null 2>&1

POLICY=secondary IP=192.0.2.20/33
export POLICY IP
! sh "$SRC" "$D" "$D/cidr.nft" >/dev/null 2>&1

IP=999.0.2.20 MAC=AA:BB:CC:DD:EE:01
export IP MAC
! sh "$SRC" "$D" "$D/ip.nft" >/dev/null 2>&1

IP=192.0.2.20 MAC=invalid
export IP MAC
! sh "$SRC" "$D" "$D/mac.nft" >/dev/null 2>&1

MAC=AA:BB:CC:DD:EE:01 BM=0x4A01
export MAC BM
! sh "$SRC" "$D" "$D/mark.nft" >/dev/null 2>&1

TM=0x4A01 BM=0x4A02 PM=0x4A03 POLICY=secondary
export TM BM PM POLICY
ENABLED=0 IP=192.0.2.99 MAC=AA:BB:CC:DD:EE:99
export ENABLED IP MAC
sh "$SRC" "$D" "$D/disabled.nft" >/dev/null
! grep -q "192.0.2.99" "$D/disabled.nft"
ENABLED=1 IP= MAC=
export ENABLED IP MAC
! sh "$SRC" "$D" "$D/empty.nft" >/dev/null 2>&1
echo TRAFFIC_PLAN_UCI_11_CHECKS_OK
