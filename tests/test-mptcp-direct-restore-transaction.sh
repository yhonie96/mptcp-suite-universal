#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-direct-restore}"
D="${TMPDIR:-/tmp}/direct-restore-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/direct" "$D/config" "$D/state"
printf TUNNEL_MAIN >"$D/config/main.json"
printf TUNNEL_LIMIT >"$D/config/limit.json"
printf DIRECT_MAIN >"$D/direct/main.json"
printf DIRECT_LIMIT >"$D/direct/limit5.json"
printf 'main\t%s\txray\tvless\tfreedom\t%s\n' "$D/config/main.json" "$D/tunnel-main.json" >"$D/manifest"
printf 'limit5\t%s\txray-5mbps\tvless-5mbps\tfreedom-5mbps\t%s\n' "$D/config/limit.json" "$D/tunnel-limit.json" >>"$D/manifest"
cat >"$D/bin/step" <<'EOF'
#!/bin/sh
name="${0##*/}"; echo "$name $*" >>"$MOCK_LOG"
[ "${MOCK_FAIL:-}" = "$name" ] && exit 1
exit 0
EOF
for n in xray nft ip restart; do cp "$D/bin/step" "$D/bin/$n"; chmod 755 "$D/bin/$n"; done
run(){
 env MOCK_LOG="$D/actions" MOCK_FAIL="${MOCK_FAIL:-}" \
 MPTCP_MANIFEST="$D/manifest" MPTCP_DIRECT_SNAPSHOT_DIR="$D/direct" \
 MPTCP_PROFILE_RESTART="$D/bin/restart" MPTCP_PAUSED_FILE="$D/state/paused" \
 MPTCP_NFT_BIN="$D/bin/nft" MPTCP_IP_BIN="$D/bin/ip" MPTCP_XRAY_BIN="$D/bin/xray" \
 "$F" --apply
}
reset(){ printf TUNNEL_MAIN >"$D/config/main.json"; printf TUNNEL_LIMIT >"$D/config/limit.json"; rm -f "$D/state/paused"; : >"$D/actions"; }
reset; run | grep -Fq DIRECT_RESTORE_OK
grep -qx DIRECT_MAIN "$D/config/main.json"
grep -qx DIRECT_LIMIT "$D/config/limit.json"
[ -e "$D/state/paused" ]
grep -Fq 'nft delete table ip mptcp_tproxy' "$D/actions"
grep -Fq 'ip mptcp endpoint flush' "$D/actions"
grep -Fq 'restart ' "$D/actions"
[ "$(grep -Fc 'xray run -test -c' "$D/actions")" -eq 2 ]
echo DIRECT_RESTORE_TRANSACTION_OK
mv "$D/direct/main.json" "$D/direct/main.off"
reset; set +e; out="$(run 2>&1)"; rc=$?; set -e
[ "$rc" -eq 4 ]; echo "$out" | grep -Fq ERROR=missing_direct:main
mv "$D/direct/main.off" "$D/direct/main.json"
echo DIRECT_RESTORE_MISSING_SNAPSHOT_OK
reset; set +e; out="$(MOCK_FAIL=xray run 2>&1)"; rc=$?; set -e
[ "$rc" -eq 5 ]; echo "$out" | grep -Fq ERROR=invalid_direct:main
[ ! -e "$D/state/paused" ]
echo DIRECT_RESTORE_INVALID_SNAPSHOT_OK
reset; set +e; out="$(MOCK_FAIL=restart run 2>&1)"; rc=$?; set -e
[ "$rc" -eq 7 ]; echo "$out" | grep -Fq ERROR=profile_restart
[ ! -e "$D/state/paused" ]
echo DIRECT_RESTORE_RESTART_FAIL_OK
