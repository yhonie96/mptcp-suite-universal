#!/bin/sh
set -eu
APPLY="$PWD/mptcp-suite-traffic/files/usr/sbin/traffic-policy-apply"
INIT="$PWD/mptcp-suite-traffic/files/etc/init.d/traffic-policy"
MON="$PWD/mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor"

grep -Fq 'flock -n 9' "$APPLY"
grep -Fq 'install_rule()' "$INIT"
grep -Fq 'actual_policy_mode()' "$MON"

# Verify traffic-policy-apply rejects concurrent lock without stale directory lock
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
(
 exec 9>"$D/apply.lock"
 flock -n 9
 set +e
 OUT="$(MPTCP_TRAFFIC_POLICY_LOCK="$D/apply.lock" "$APPLY" 2>&1)"
 RC=$?
 set -e
 [ "$RC" -eq 2 ]
 echo "$OUT" | grep -qx APPLY_BUSY
)
echo PAUSED_MODE_HARDENING_OK
