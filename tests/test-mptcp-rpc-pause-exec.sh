#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp}"
D="${TMPDIR:-/tmp}/mptcp-rpc-pause-exec-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/suite" "$D/bin" "$D/init.d" "$D/profile"
printf '{}\n' >"$D/profile/main.json"
printf '{}\n' >"$D/profile/main.snap"
printf 'main\t%s\tmain-svc\t12345\t3443\t%s\n' "$D/profile/main.json" "$D/profile/main.snap" >"$D/suite/tunnel-profiles.tsv"
printf 'placeholder\n' >"$D/suite/make-direct.uc"
cat >"$D/bin/helper" <<'MOCK'
#!/bin/sh
echo "${0##*/} $*" >>"$MOCK_LOG"
[ "${MOCK_FAIL:-}" = "${0##*/}" ] && exit 1
exit 0
MOCK
for N in snapshot backup restart routing-clear nft ip; do cp "$D/bin/helper" "$D/bin/$N"; chmod 755 "$D/bin/$N"; done
cat >"$D/bin/ucode" <<'MOCK'
#!/bin/sh
echo "ucode $*" >>"$MOCK_LOG"
cp "$2" "$3"
MOCK
cat >"$D/bin/xray" <<'MOCK'
#!/bin/sh
echo "xray $*" >>"$MOCK_LOG"
exit 0
MOCK
chmod 755 "$D/bin/ucode" "$D/bin/xray"
for N in main-svc bsbf-bonding-nft mptcp-autoreconnect bsbf-endpoint-repair bsbf-mptcp traffic-policy mptcp-paused-failover; do cp "$D/bin/helper" "$D/init.d/$N"; chmod 755 "$D/init.d/$N"; done
run(){
 env MOCK_LOG="$D/actions" MOCK_FAIL="${MOCK_FAIL:-}" MPTCP_SUITE_DIR="$D/suite" \
 MPTCP_PROFILE_BACKUP="$D/bin/backup" MPTCP_PROFILE_RESTART="$D/bin/restart" \
 MPTCP_DIRECT_SNAPSHOT="$D/bin/snapshot" MPTCP_ROUTING_CLEAR="$D/bin/routing-clear" \
 MPTCP_UCODE_BIN="$D/bin/ucode" MPTCP_XRAY_BIN="$D/bin/xray" MPTCP_INITD_DIR="$D/init.d" \
 MPTCP_NFT_BIN="$D/bin/nft" MPTCP_IP_BIN="$D/bin/ip" "$F" call pause
}
: >"$D/actions"
out="$(run)"
echo "$out" | jsonfilter -e '@.ok' | grep -qx true
echo "$out" | jsonfilter -e '@.message' | grep -qx 'MPTCP dijeda; Direct aktif'
[ -e "$D/suite/paused" ]
grep -qx 'routing-clear --apply' "$D/actions"
grep -qx 'restart ' "$D/actions"
CL="$(grep -n 'routing-clear --apply' "$D/actions" | cut -d: -f1)"
RL="$(grep -n 'restart ' "$D/actions" | cut -d: -f1)"
[ "$CL" -lt "$RL" ]
grep -qx 'traffic-policy reload' "$D/actions"
grep -qx 'mptcp-paused-failover start' "$D/actions"
echo MPTCP_RPC_ACTIVE_TO_PAUSE_CLEAR_OK
rm -f "$D/suite/paused"; : >"$D/actions"
set +e; out="$(MOCK_FAIL=routing-clear run)"; rc=$?; set -e
[ "$rc" -eq 0 ]
echo "$out" | jsonfilter -e '@.ok' | grep -qx false
[ -e "$D/suite/paused" ]
! grep -qx 'restart ' "$D/actions"
echo MPTCP_RPC_ACTIVE_TO_PAUSE_CLEAR_FAIL_SAFE_OK
: >"$D/actions"; touch "$D/suite/paused"
out="$(run)"
echo "$out" | jsonfilter -e '@.ok' | grep -qx true
grep -qx 'routing-clear --apply' "$D/actions"
! grep -qx 'backup ' "$D/actions"
echo MPTCP_RPC_ALREADY_PAUSED_CLEAR_OK
