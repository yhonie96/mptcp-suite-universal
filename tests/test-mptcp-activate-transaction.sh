#!/bin/sh
set -eu
A="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-activate}"
D="${TMPDIR:-/tmp}/mptcp-activate-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/etc" "$D/work"
printf paused >"$D/paused"
printf DIRECT_MAIN >"$D/main.json"
printf DIRECT_LIMIT >"$D/limit.json"
printf TUNNEL_MAIN >"$D/tunnel-main.json"
printf TUNNEL_LIMIT >"$D/tunnel-limit.json"
printf 'main\t%s\txray\tvless\tfreedom\t%s\n' "$D/main.json" "$D/tunnel-main.json" >"$D/manifest"
printf 'limit5\t%s\txray-5mbps\tvless-5mbps\tfreedom-5mbps\t%s\n' "$D/limit.json" "$D/tunnel-limit.json" >>"$D/manifest"
cat >"$D/bin/step" <<'EOF'
#!/bin/sh
name="${0##*/}"; echo "$name $* SNAP=${MPTCP_ROUTING_SNAPSHOT:-}" >>"$MOCK_LOG"
[ "${MOCK_FAIL:-}" = "$name" ] && exit 1
case "$name" in curl) printf '%s' "${MOCK_HTTP:-204}";; ip) [ "${2:-}" = endpoint ] && printf 'a\nb\n';; ss) printf 'subflows_total:%s\n' "${MOCK_SF:-2}";; esac
exit 0
EOF
for n in precheck routing rollback direct-restore restart reconnect sync curl ip ss xray; do cp "$D/bin/step" "$D/bin/$n"; chmod 755 "$D/bin/$n"; done
run(){
 env MOCK_LOG="$D/actions" MOCK_FAIL="${MOCK_FAIL:-}" MOCK_HTTP="${MOCK_HTTP:-204}" MOCK_SF="${MOCK_SF:-2}" \
 MPTCP_ACTIVATE_DIR="$D/work" MPTCP_MANIFEST="$D/manifest" MPTCP_PAUSED_FILE="$D/paused" \
 MPTCP_PRECHECK="$D/bin/precheck" MPTCP_ROUTING_EXEC="$D/bin/routing" MPTCP_ROUTING_ROLLBACK="$D/bin/rollback" \
 MPTCP_DIRECT_RESTORE="$D/bin/direct-restore" MPTCP_PROFILE_RESTART="$D/bin/restart" MPTCP_RECONNECT="$D/bin/reconnect" \
 MPTCP_SYNC_5M="$D/bin/sync" MPTCP_CURL_BIN="$D/bin/curl" MPTCP_IP_BIN="$D/bin/ip" MPTCP_SS_BIN="$D/bin/ss" \
 MPTCP_XRAY_BIN="$D/bin/xray" "$A" --apply
}
reset(){ printf paused >"$D/paused"; printf DIRECT_MAIN >"$D/main.json"; printf DIRECT_LIMIT >"$D/limit.json"; : >"$D/actions"; rm -rf "$D/work"; }
reset; set +e; out="$(run 2>&1)"; rc=$?; set -e; echo "$out"; [ "$rc" -eq 0 ]; echo "$out" | grep -Fq MPTCP_ACTIVATE_OK
[ ! -e "$D/paused" ]; grep -qx TUNNEL_MAIN "$D/main.json"; grep -Fq 'routing --apply SNAP=' "$D/actions"
echo MPTCP_ACTIVATE_SUCCESS_OK
for fail in precheck routing restart reconnect; do
 reset; set +e; out="$(MOCK_FAIL="$fail" run 2>&1)"; rc=$?; set -e
 [ "$rc" -ne 0 ]; [ -e "$D/paused" ]; echo "$out" | grep -Fq MPTCP_ACTIVATE_ROLLBACK
 grep -Fq 'direct-restore --apply' "$D/actions"; grep -Fq 'rollback --apply SNAP=' "$D/actions"
 echo "MPTCP_ACTIVATE_${fail}_ROLLBACK_OK"
done
reset; set +e; out="$(MOCK_HTTP=000 run 2>&1)"; rc=$?; set -e
[ "$rc" -ne 0 ]; [ -e "$D/paused" ]; echo "$out" | grep -Fq 'stage=validate'
echo MPTCP_ACTIVATE_HTTP_ROLLBACK_OK
reset
out="$(MOCK_SF=1 run)"
echo "$out" | grep -Fq 'MPTCP_ACTIVATE_OK'
[ ! -e "$D/paused" ]
echo MPTCP_ACTIVATE_SUBFLOW_DIAGNOSTIC_OK
grep -Fq 'bsbf-mptcp stop' "$A"
echo MPTCP_ACTIVATE_ROLLBACK_SERVICE_OK
