#!/bin/sh
set -eu
M=mptcp-suite-routing/files/usr/libexec/mptcp-suite/paused-failover-monitor
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
cat >"$D/uci" <<'MOCK'
#!/bin/sh
case "$*" in *failover.enabled) echo "${ENABLED:-1}";; *primary_interface|*secondary_interface) exit 1;; *core.primary_wan) echo uplink_a;; *core.secondary_wan) echo uplink_b;; *failure_threshold|*recovery_threshold) echo 3;; *failover.interval) echo 1;; *check_url) echo url;; *uplink_a.device) echo eth1;; *uplink_a.gateway) echo 192.168.8.1;; *uplink_a.metric) echo 7;; *uplink_b.device) echo phy0-sta0;; *uplink_b.gateway) echo 192.168.1.1;; *uplink_b.metric) echo 9;; esac
MOCK
cat >"$D/curl" <<'MOCK'
#!/bin/sh
case "$*" in *eth1*) echo "${PHTTP:-204}";; *phy0-sta0*) echo "${SHTTP:-204}";; esac
MOCK
cat >"$D/ip" <<'MOCK'
#!/bin/sh
case "$(cat "$MODE_FILE")" in primary) echo '8.8.8.8 via 192.168.8.1 dev eth1';; secondary) echo '8.8.8.8 via 192.168.1.1 dev phy0-sta0';; unknown) echo '8.8.8.8 dev lo';; esac
MOCK
cat >"$D/route" <<'MOCK'
#!/bin/sh
echo "$2" >>"$ACTIONS"
[ "${ROUTE_FAIL:-0}" = 1 ] && exit 1
case "$2" in FAILOVER) echo secondary >"$MODE_FILE";; RESTORE) echo primary >"$MODE_FILE";; esac
MOCK
chmod 755 "$D/"*; echo primary >"$D/mode"; touch "$D/paused"; : >"$D/actions"
run(){ env MPTCP_UCI_BIN="$D/uci" MPTCP_CURL_BIN="$D/curl" MPTCP_IP_BIN="$D/ip" MPTCP_PAUSED_FAILOVER_ROUTE_BIN="$D/route" MPTCP_PAUSED_FILE="$D/paused" MPTCP_PAUSED_FAILOVER_STATE="$D/state" MPTCP_PAUSED_FAILOVER_ONCE=1 ACTIONS="$D/actions" MODE_FILE="$D/mode" PHTTP="${PHTTP:-204}" SHTTP="${SHTTP:-204}" ENABLED="${ENABLED:-1}" ROUTE_FAIL="${ROUTE_FAIL:-0}" "$M" --run; }
run >/dev/null; PHTTP=000 run >/dev/null; PHTTP=000 run >/dev/null; PHTTP=000 run >/dev/null
grep -qx FAILOVER "$D/actions"; [ "$(cat "$D/mode")" = secondary ]
# Restart derives secondary from route, not state
rm -f "$D/state"; PHTTP=204 run >/dev/null; grep -q 'RC=1' "$D/state"
PHTTP=204 run >/dev/null; PHTTP=204 run >/dev/null; grep -qx RESTORE "$D/actions"; echo primary >"$D/mode"
# Corrupt state is ignored
printf 'FC=bad\nRC=$(reboot)\n' >"$D/state"; run >/dev/null; grep -q '^FC=0' "$D/state"
# Leaving paused restores secondary
printf secondary >"$D/mode"; rm -f "$D/paused"; run | grep -qx MONITOR_IDLE; grep -qx RESTORE "$D/actions"
# Disabled restores secondary
printf secondary >"$D/mode"; touch "$D/paused"; ENABLED=0 run | grep -qx MONITOR_IDLE
# Restore failure is reported and state retained safely
printf secondary >"$D/mode"; set +e; O="$(ENABLED=0 ROUTE_FAIL=1 run 2>&1)"; R=$?; set -e; [ "$R" -ne 0 ]; echo "$O" | grep -Fq ERROR=restore_primary_failed
echo PAUSED_FAILOVER_MONITOR_V2_OK
