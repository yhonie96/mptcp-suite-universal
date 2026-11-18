#!/bin/sh
set -eu
A="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-activate}"
D="${TMPDIR:-/tmp}/mptcp-diversion-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/work"
printf paused >"$D/paused"
printf DIRECT_MAIN >"$D/main.json"
printf DIRECT_LIMIT >"$D/limit.json"
printf TUNNEL_MAIN >"$D/tunnel-main.json"
printf TUNNEL_LIMIT >"$D/tunnel-limit.json"
printf NFT >"$D/bonding.nft"
printf 'main\t%s\txray\tvless\tfreedom\t%s\n' "$D/main.json" "$D/tunnel-main.json" >"$D/manifest"
printf 'limit5\t%s\txray-5mbps\tvless-5mbps\tfreedom-5mbps\t%s\n' "$D/limit.json" "$D/tunnel-limit.json" >>"$D/manifest"
cat >"$D/bin/step" <<'EOF'
#!/bin/sh
name="${0##*/}"
echo "$name $* SNAP=${MPTCP_ROUTING_SNAPSHOT:-}" >>"$MOCK_LOG"
[ "${MOCK_FAIL:-}" = "$name" ] && exit 1
case "$name" in
 curl) printf '%s' "${MOCK_HTTP:-204}" ;;
 ip) [ "${2:-}" = endpoint ] && printf 'a\nb\n' ;;
 uci) case "$*" in *main.local_port) echo 12345;; *limit5.local_port) echo 12346;; esac ;;
 ss) case "$*" in
  "-Mi") printf "subflows_total:%s\n" "${MOCK_SF:-2}" ;;
  "-H -lnt") printf "LISTEN 0 4096 127.0.0.1:12345 x\nLISTEN 0 4096 127.0.0.1:12346 x\n" ;;
  "-H -lnu") printf "UNCONN 0 0 127.0.0.1:12345 x\nUNCONN 0 0 127.0.0.1:12346 x\n" ;;
 esac ;;
esac
exit 0
EOF
cat >"$D/bin/nft" <<'EOF'
#!/bin/sh
echo "nft $*" >>"$MOCK_LOG"
case "$*" in
 "-c -f "*) [ "${NFT_FAIL:-}" = check ] && exit 1 ;;
 "-f "*) [ "${NFT_FAIL:-}" = load ] && exit 1 ;;
 "list table ip bsbf_bonding") [ "${NFT_FAIL:-}" = table ] && exit 1 ;;
 "list set ip bsbf_bonding netcontrol_5m") [ "${NFT_FAIL:-}" = set ] && exit 1 ;;
esac
exit 0
EOF
cat >"$D/bin/generator" <<'EOF'
#!/bin/sh
echo "generator $*" >>"$MOCK_LOG"
[ "${GEN_FAIL:-0}" = 1 ] && exit 1
printf 'table ip bsbf_bonding {}\n' >"$1"
EOF
chmod 755 "$D/bin/generator"
for n in precheck routing rollback direct-restore restart reconnect sync curl ip ss xray uci; do cp "$D/bin/step" "$D/bin/$n"; chmod 755 "$D/bin/$n"; done
chmod 755 "$D/bin/nft"
run(){
 env MOCK_LOG="$D/actions" MOCK_FAIL="${MOCK_FAIL:-}" MOCK_HTTP="${MOCK_HTTP:-204}" MOCK_SF="${MOCK_SF:-2}" NFT_FAIL="${NFT_FAIL:-}" GEN_FAIL="${GEN_FAIL:-0}" \
 MPTCP_ACTIVATE_DIR="$D/work" MPTCP_MANIFEST="$D/manifest" MPTCP_PAUSED_FILE="$D/paused" \
 MPTCP_PRECHECK="$D/bin/precheck" MPTCP_ROUTING_EXEC="$D/bin/routing" MPTCP_ROUTING_ROLLBACK="$D/bin/rollback" \
 MPTCP_DIRECT_RESTORE="$D/bin/direct-restore" MPTCP_PROFILE_RESTART="$D/bin/restart" MPTCP_RECONNECT="$D/bin/reconnect" \
 MPTCP_SYNC_5M="$D/bin/sync" MPTCP_CURL_BIN="$D/bin/curl" MPTCP_IP_BIN="$D/bin/ip" MPTCP_SS_BIN="$D/bin/ss" \
 MPTCP_UCI_BIN="$D/bin/uci" MPTCP_XRAY_BIN="$D/bin/xray" MPTCP_NFT_BIN="$D/bin/nft" MPTCP_NFT_GENERATOR="$D/bin/generator" MPTCP_NFT_FILE="$D/bonding.nft" "$A" --apply
}
reset(){ printf paused >"$D/paused"; printf DIRECT_MAIN >"$D/main.json"; printf DIRECT_LIMIT >"$D/limit.json"; : >"$D/actions"; rm -rf "$D/work"; }
reset
out="$(run)"; echo "$out" | grep -Fq MPTCP_ACTIVATE_OK
[ ! -e "$D/paused" ]
grep -Fq "generator $D/bonding.nft" "$D/actions"
grep -Fq "nft -c -f $D/bonding.nft" "$D/actions"
grep -Fq "nft -f $D/bonding.nft" "$D/actions"
grep -Fq 'nft list table ip bsbf_bonding' "$D/actions"
grep -Fq 'nft list set ip bsbf_bonding netcontrol_5m' "$D/actions"
echo MPTCP_DIVERSION_SUCCESS_OK
for fail in check load table set; do
 reset; set +e; out="$(NFT_FAIL="$fail" run 2>&1)"; rc=$?; set -e
 [ "$rc" -ne 0 ]; [ -e "$D/paused" ]; echo "$out" | grep -Fq MPTCP_ACTIVATE_ROLLBACK
 grep -Fq 'nft delete table ip bsbf_bonding' "$D/actions"
 case "$fail" in check) stage=diversion_check;; load) stage=diversion_load;; *) stage=diversion_validate;; esac
 echo "$out" | grep -Fq "stage=$stage"
 echo "MPTCP_DIVERSION_${fail}_ROLLBACK_OK"
done

reset; set +e; out="$(GEN_FAIL=1 run 2>&1)"; rc=$?; set -e
[ "$rc" -ne 0 ]; [ -e "$D/paused" ]
echo "$out" | grep -Fq 'stage=diversion_generate'
echo MPTCP_DIVERSION_GENERATE_ROLLBACK_OK
