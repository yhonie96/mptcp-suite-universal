#!/bin/sh
set -eu
SRC="$PWD/mptcp-suite-traffic/files/usr/libexec/mptcp-suite/traffic-plan"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin"
cat >"$T/bin/uci" <<'MOCK'
#!/bin/sh
for LAST do :; done
case "$LAST" in
*mptcp_suite.routing.tproxy_mark) echo "${TM:-0x4A01}";;
*mptcp_suite.routing.bypass_mark) echo "${BM:-0x4A02}";;
*mptcp_suite.routing.policy_mark) echo "${PM:-0x4A03}";;
esac
MOCK
chmod +x "$T/bin/uci"; PATH="$T/bin:$PATH"; export PATH
sh "$SRC" "$T" "$T/ok.nft" >/dev/null
grep -q 'table inet mptcp_suite' "$T/ok.nft"
grep -q 'meta mark set 0x4A01' "$T/ok.nft"
grep -q 'meta mark set 0x4A02' "$T/ok.nft"
grep -q 'meta mark set 0x4A03' "$T/ok.nft"
TM=0x4A01 BM=0x4A01 PM=0x4A03; export TM BM PM
! sh "$SRC" "$T" "$T/dup.nft" >/dev/null 2>&1
TM=bad BM=0x4A02 PM=0x4A03; export TM BM PM
! sh "$SRC" "$T" "$T/bad.nft" >/dev/null 2>&1
echo TRAFFIC_PLAN_3_SCENARIOS_OK
