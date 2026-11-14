#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp}"
D="${TMPDIR:-/tmp}/mptcp-rpc-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/suite" "$D/bin"
touch "$D/suite/paused"
cat >"$D/bin/helper" <<'EOF'
#!/bin/sh
echo "${0##*/} $*" >>"$MOCK_LOG"
[ "${MOCK_FAIL:-}" = "${0##*/}" ] && exit 1
exit 0
EOF
for n in snapshot precheck activate; do cp "$D/bin/helper" "$D/bin/$n"; chmod 755 "$D/bin/$n"; done
run(){
 env MOCK_LOG="$D/actions" MOCK_FAIL="${MOCK_FAIL:-}" MPTCP_SUITE_DIR="$D/suite" \
 MPTCP_DIRECT_SNAPSHOT="$D/bin/snapshot" MPTCP_RESUME_CHECK="$D/bin/precheck" MPTCP_ACTIVATE="$D/bin/activate" \
 "$F" call "$1"
}
: >"$D/actions"
out="$(run resume_check)"; echo "$out" | jsonfilter -e '@.ok' | grep -qx true
echo "$out" | jsonfilter -e '@.message' | grep -qx 'Aktivasi siap'
grep -qx 'precheck ' "$D/actions"
echo MPTCP_RPC_RESUME_CHECK_OK
set +e; out="$(MOCK_FAIL=precheck run resume_check)"; rc=$?; set -e
[ "$rc" -eq 0 ]; echo "$out" | jsonfilter -e '@.ok' | grep -qx false
echo MPTCP_RPC_RESUME_CHECK_FAIL_OK
: >"$D/actions"; out="$(run resume)"; echo "$out" | jsonfilter -e '@.ok' | grep -qx true
echo "$out" | jsonfilter -e '@.message' | grep -qx 'MPTCP aktif'
grep -qx 'activate --apply' "$D/actions"
echo MPTCP_RPC_RESUME_OK
rm -f "$D/suite/paused"; set +e; out="$(MOCK_FAIL=activate run resume)"; rc=$?; set -e
[ "$rc" -eq 0 ]; echo "$out" | jsonfilter -e '@.ok' | grep -qx false
[ -e "$D/suite/paused" ]; echo "$out" | jsonfilter -e '@.message' | grep -qx 'Aktivasi gagal; Direct dipertahankan'
echo MPTCP_RPC_RESUME_FAIL_SAFE_OK
# Pause integration is kept structural because direct_mode intentionally touches multiple absolute services.
grep -Fq '"$DIRECT_SNAPSHOT" --apply' "$F"
grep -Fq 'Direct aktif, tetapi snapshot rollback gagal' "$F"
echo MPTCP_RPC_PAUSE_SNAPSHOT_STRUCTURE_OK
