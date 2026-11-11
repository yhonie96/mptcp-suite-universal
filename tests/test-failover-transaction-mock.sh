#!/bin/sh
set -eu
E=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-exec
D="$(mktemp -d)"
trap 'rm -rf "$D" /tmp/mptcp-failover.lock /tmp/mptcp-failover.routes' EXIT
mkdir -p "$D/bin"

cat >"$D/apply" <<'MOCK'
#!/bin/sh
echo "$1" >>"$MOCK_ACTIONS"
case "$1" in
 FAILOVER) echo "ip route replace default via 192.168.1.1 dev phy0-sta0 table 102 metric 9" ;;
 RESTORE) echo "ip route replace default via 192.168.8.1 dev eth1 table 102 metric 7" ;;
esac
MOCK

cat >"$D/bin/ip" <<'MOCK'
#!/bin/sh
echo "$*" >>"$MOCK_EXEC"
case "$*" in
 "route show"*) echo "default via 192.168.8.1 dev eth1 metric 7" ;;
esac
MOCK

cat >"$D/bin/curl" <<'MOCK'
#!/bin/sh
echo "${MOCK_HTTP:-204}"
MOCK

chmod 755 "$D/apply" "$D/bin/"*
export MOCK_ACTIONS="$D/actions"
export MOCK_EXEC="$D/executed"
export MPTCP_FAILOVER_APPLY=1
export MPTCP_FAILOVER_APPLY_BIN="$D/apply"
export PATH="$D/bin:$PATH"

MOCK_HTTP=204 sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102
grep -qx FAILOVER "$MOCK_ACTIONS"
grep -Fq "route replace default via 192.168.1.1" "$MOCK_EXEC"

: >"$MOCK_ACTIONS"
: >"$MOCK_EXEC"
export MOCK_HTTP=000
! sh "$E" --apply FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102
grep -qx FAILOVER "$MOCK_ACTIONS"
grep -qx RESTORE "$MOCK_ACTIONS"
grep -Fq "route replace default via 192.168.8.1" "$MOCK_EXEC"

echo FAILOVER_TRANSACTION_MOCK_OK
