#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-restore
test -x "$F"
grep -Fq "restore_route()" "$F"
grep -Fq "restore_rule()" "$F"
grep -Fq "ERROR=unsafe_snapshot" "$F"
! grep -Fq "lookup main" "$F"
D="$(mktemp -d)"
trap 'rm -rf "$D"' EXIT
mkdir "$D/bin"
cat >"$D/bin/ip" <<'MOCK'
#!/bin/sh
echo "$*" >>"$MOCK_LOG"
MOCK
chmod 755 "$D/bin/ip"
export PATH="$D/bin:$PATH"
export MOCK_LOG="$D/log"
cat >"$D/snap" <<'SNAP'
TABLE_PRIMARY
default via 10.0.0.1 dev eth9 metric 7
TABLE_SECONDARY
default via 20.0.0.1 dev usb9 metric 9
TABLE_TPROXY
local default dev lo scope host
RULES
98: from all fwmark 0x4A02 lookup 11001
99: from all fwmark 0x4A03 lookup 11002
100: from all fwmark 0x4A01 lookup 11003
SNAP
sh "$F" "$D/snap" 11001 11002 11003 98 99 100
grep -Fq "route replace default via 10.0.0.1 dev eth9 table 11001 metric 7" "$MOCK_LOG"
grep -Fq "route replace default via 20.0.0.1 dev usb9 table 11002 metric 9" "$MOCK_LOG"
grep -Fq "route replace local 0.0.0.0/0 dev lo table 11003" "$MOCK_LOG"
grep -Fq "rule add priority 98 fwmark 0x4A02 lookup 11001" "$MOCK_LOG"
grep -Fq "rule add priority 99 fwmark 0x4A03 lookup 11002" "$MOCK_LOG"
grep -Fq "rule add priority 100 fwmark 0x4A01 lookup 11003" "$MOCK_LOG"
: >"$MOCK_LOG"
echo reboot >>"$D/snap"
! sh "$F" "$D/snap" 11001 11002 11003 98 99 100 >/dev/null 2>&1
test ! -s "$MOCK_LOG"
echo ROUTING_SNAPSHOT_RESTORE_OK
