#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-boot-restore}"
D="${TMPDIR:-/tmp}/mptcp-boot-test-$$"; trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/state"
cat >"$D/bin/helper" <<'EOF'
#!/bin/sh
echo "${0##*/} $* DIR=${MPTCP_DIRECT_SNAPSHOT_DIR:-}" >>"$MOCK_LOG"
[ "${MOCK_FAIL:-}" = "${0##*/}" ] && exit 1
exit 0
EOF
for n in direct activate; do cp "$D/bin/helper" "$D/bin/$n"; chmod 755 "$D/bin/$n"; done
run(){ env MOCK_LOG="$D/log" MOCK_FAIL="${MOCK_FAIL:-}" MPTCP_PAUSED_FILE="$D/state/paused" MPTCP_DIRECT_RESTORE="$D/bin/direct" MPTCP_ACTIVATE="$D/bin/activate" MPTCP_DIRECT_SNAPSHOT_DIR="$D/direct" "$F" --apply; }
touch "$D/state/paused"; run | grep -Fq MPTCP_BOOT_PAUSED_OK; [ ! -s "$D/log" ]
echo MPTCP_BOOT_PAUSED_OK
rm -f "$D/state/paused"; : >"$D/log"; run | grep -Fq MPTCP_BOOT_ACTIVE_OK; grep -Fq 'direct --apply DIR=' "$D/log"; grep -Fq 'activate --apply' "$D/log"
echo MPTCP_BOOT_ACTIVE_OK
rm -f "$D/state/paused"; set +e; out="$(MOCK_FAIL=direct run 2>&1)"; rc=$?; set -e; [ "$rc" -eq 3 ]; [ -e "$D/state/paused" ]; echo "$out" | grep -Fq ERROR=boot_direct_restore
echo MPTCP_BOOT_DIRECT_FAIL_SAFE_OK
rm -f "$D/state/paused"; set +e; out="$(MOCK_FAIL=activate run 2>&1)"; rc=$?; set -e; [ "$rc" -eq 4 ]; [ -e "$D/state/paused" ]; echo "$out" | grep -Fq ERROR=boot_activate
echo MPTCP_BOOT_ACTIVATE_FAIL_SAFE_OK

grep -Fq 'touch "$PAUSED"' "$F"
