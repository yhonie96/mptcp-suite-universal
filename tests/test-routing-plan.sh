#!/bin/sh
set -eu
SRC="$PWD/mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-plan"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"

cat >"$T/bin/uci" <<'MOCK'
#!/bin/sh
for LAST do :; done
case "$LAST" in
*mptcp_suite.core.primary_wan) echo wan;;
*mptcp_suite.core.secondary_wan) [ "${ONE_WAN:-0}" = 1 ] || echo wwan;;
*mptcp_suite.routing.primary_table) echo "${PT:-11001}";;
*mptcp_suite.routing.secondary_table) echo "${ST:-11002}";;
*mptcp_suite.routing.tproxy_table) echo "${TT:-11003}";;
*mptcp_suite.routing.tproxy_mark) echo "${TM:-0x4A01}";;
*mptcp_suite.routing.bypass_mark) echo "${BM:-0x4A02}";;
*mptcp_suite.routing.policy_mark) echo "${PM:-0x4A03}";;
*mptcp_suite.routing.primary_priority) echo "${BP:-98}";;
*mptcp_suite.routing.secondary_priority) echo "${PP:-99}";;
*mptcp_suite.routing.tproxy_priority) echo "${TP:-100}";;
esac
MOCK

cat >"$T/bin/ifstatus" <<'MOCK'
#!/bin/sh
case "$1" in
wan) printf '%s\n' '{"l3_device":"eth9","ipv4-address":[{"address":"10.0.0.2"}],"route":[{"nexthop":"10.0.0.1"}]}' ;;
wwan)
 [ "${SECONDARY_DOWN:-0}" = 1 ] && exit 1
 if [ "${EMPTY_GATEWAY:-0}" = 1 ]; then
  printf '%s\n' '{"l3_device":"usb9","ipv4-address":[{"address":"20.0.0.2"}],"route":[]}'
 else
  printf '%s\n' '{"l3_device":"usb9","ipv4-address":[{"address":"20.0.0.2"}],"route":[{"nexthop":"20.0.0.1"}]}'
 fi ;;
esac
MOCK

cat >"$T/bin/jsonfilter" <<'MOCK'
#!/bin/sh
J="$(cat)"
case "$*" in
*"l3_device"*) printf '%s' "$J" | sed -n 's/.*"l3_device":"\([^"]*\)".*/\1/p';;
*"ipv4-address"*) printf '%s' "$J" | sed -n 's/.*"address":"\([^"]*\)".*/\1/p';;
*"nexthop"*) printf '%s' "$J" | sed -n 's/.*"nexthop":"\([^"]*\)".*/\1/p';;
esac
MOCK

chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH"

sh "$SRC" "$T" "$T/normal.plan" >/dev/null
test "$(wc -l < "$T/normal.plan")" -eq 6
grep -qx 'ip route replace default via 10.0.0.1 dev eth9 table 11001' "$T/normal.plan"
grep -qx 'ip route replace default via 20.0.0.1 dev usb9 table 11002' "$T/normal.plan"
grep -qx 'ip route replace local 0.0.0.0/0 dev lo table 11003' "$T/normal.plan"

ONE_WAN=1; export ONE_WAN
! sh "$SRC" "$T" "$T/one.plan" >/dev/null 2>&1
unset ONE_WAN
SECONDARY_DOWN=1; export SECONDARY_DOWN
! sh "$SRC" "$T" "$T/down.plan" >/dev/null 2>&1
unset SECONDARY_DOWN
EMPTY_GATEWAY=1; export EMPTY_GATEWAY
! sh "$SRC" "$T" "$T/gateway.plan" >/dev/null 2>&1
unset EMPTY_GATEWAY
PT=11001 ST=11001; export PT ST
! sh "$SRC" "$T" "$T/duplicate.plan" >/dev/null 2>&1

PT=11001 ST=11002 TM=0x4A01 BM=0x4A01; export PT ST TM BM
! sh "$SRC" "$T" "$T/duplicate-mark.plan" >/dev/null 2>&1
PT=11001 ST=11002 TM=0x4A01 BM=0x4A02 BP=98 PP=98 TP=100
export PT ST TM BM BP PP TP
! sh "$SRC" "$T" "$T/duplicate-priority.plan" >/dev/null 2>&1
BP=0 PP=99 TP=100; export BP PP TP
! sh "$SRC" "$T" "$T/priority-range.plan" >/dev/null 2>&1
BP=bad; export BP
! sh "$SRC" "$T" "$T/priority-invalid.plan" >/dev/null 2>&1
BP=98 PT=0; export BP PT
! sh "$SRC" "$T" "$T/table-range.plan" >/dev/null 2>&1
PT=bad; export PT
! sh "$SRC" "$T" "$T/table-invalid.plan" >/dev/null 2>&1
PT=11001 BP=; export PT BP
! sh "$SRC" "$T" "$T/priority-missing.plan" >/dev/null 2>&1
echo ROUTING_PLAN_12_SCENARIOS_OK
