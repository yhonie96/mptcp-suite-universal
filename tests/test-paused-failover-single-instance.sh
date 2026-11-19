#!/bin/sh
set -eu
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
grep -Fq 'MPTCP_PAUSED_FAILOVER_MONITOR_LOCK' "$M"
grep -Fq 'flock -n 8' "$M"
grep -Fq 'ERROR=locked' "$M"
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
cat >"$D/flock" <<'MOCK'
#!/bin/sh
exit 1
MOCK
chmod 755 "$D/flock"
OUT="$(PATH="$D:$PATH" MPTCP_PAUSED_FAILOVER_MONITOR_LOCK="$D/lock" "$M" --run)"
[ "$OUT" = ERROR=locked ]
echo PAUSED_FAILOVER_SINGLE_INSTANCE_V8_OK
