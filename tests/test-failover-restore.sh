#!/bin/sh
set -eu
F=mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-restore
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
=== MAIN ===
default via 192.168.8.1 dev eth1 metric 7
default via 192.168.1.1 dev phy0-sta0 metric 9
=== TABLE ===
default via 192.168.8.1 dev eth1 metric 7
SNAP

sh "$F" "$D/snap" 102
grep -Fq 'route replace default via 192.168.8.1 dev eth1 metric 7' "$MOCK_LOG"
grep -Fq 'route replace default via 192.168.1.1 dev phy0-sta0 metric 9' "$MOCK_LOG"
grep -Fq 'table 102 metric 7' "$MOCK_LOG"

echo 'reboot' >>"$D/snap"
! sh "$F" "$D/snap" 102 >/dev/null 2>&1
echo FAILOVER_SNAPSHOT_RESTORE_OK
