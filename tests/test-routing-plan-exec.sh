#!/bin/sh
set -eu
E=mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-exec
D="$(mktemp -d)"
trap 'rm -rf "$D" /tmp/mptcp-routing.lock' EXIT
mkdir "$D/bin"
printf '#!/bin/sh\necho "$*" >>"$MOCK_LOG"\n' >"$D/bin/ip"
chmod 755 "$D/bin/ip"
export PATH="$D/bin:$PATH"
export MOCK_LOG="$D/log"
P="$D/plan"
: >"$MOCK_LOG"
echo "ip route replace default via 10.0.0.1 dev eth9 table 99999" >"$P"
set +e
OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-plan 2>&1)"
RC=$?
set -e
[ "$RC" -eq 2 ]
[ "$OUT" = ERROR=unsafe_command ]
test ! -s "$MOCK_LOG"
echo ROUTING_PLAN_FOREIGN_TABLE_REJECT_OK
: >"$MOCK_LOG"
printf "%s\n" "ip route replace default via 10.0.0.1 dev eth9 table 11001" "ip route replace default via 20.0.0.1 dev usb9 table 11002" "ip route replace local 0.0.0.0/0 dev lo table 11003" >"$P"
printf "%s\n" "ip rule add priority 98 fwmark 0x4A02 lookup 11001 # primary" "ip rule add priority 99 fwmark 0x4A03 lookup 11002" "ip rule add priority 100 fwmark 0x4A01 lookup 11003" >>"$P"
MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-plan
[ "$(wc -l < "$MOCK_LOG")" -eq 6 ]
! grep -Fq "#" "$MOCK_LOG"
echo ROUTING_PLAN_EXEC_VALID_OK
: >"$MOCK_LOG"
echo "ip rule add priority 777 fwmark 0x4A02 lookup 11001" >"$P"
set +e
OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-plan 2>&1)"
RC=$?
set -e
[ "$RC" -eq 2 ]
[ "$OUT" = ERROR=unsafe_command ]
test ! -s "$MOCK_LOG"
echo ROUTING_PLAN_FOREIGN_PRIORITY_REJECT_OK
: >"$MOCK_LOG"
echo "ip rule add priority 98 fwmark 0x4A02 lookup main" >"$P"
set +e
OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-plan 2>&1)"
RC=$?
set -e
[ "$RC" -eq 2 ]
[ "$OUT" = ERROR=unsafe_command ]
test ! -s "$MOCK_LOG"
echo ROUTING_PLAN_MAIN_REJECT_OK
: >"$MOCK_LOG"
echo "ip rule add priority 98 fwmark 0xDEAD lookup 11001" >"$P"
set +e
OUT="$(MPTCP_ROUTING_TEST=1 MPTCP_ROUTING_PLAN_FILE="$P" "$E" --test-plan 2>&1)"
RC=$?
set -e
[ "$RC" -eq 2 ]
[ "$OUT" = ERROR=unsafe_command ]
test ! -s "$MOCK_LOG"
echo ROUTING_PLAN_FOREIGN_MARK_REJECT_OK
