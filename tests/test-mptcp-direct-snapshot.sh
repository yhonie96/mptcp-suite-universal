#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/usr/sbin/mptcp-direct-snapshot}"
D="${TMPDIR:-/tmp}/direct-snapshot-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/out"
printf MAIN >"$D/main.json"; printf LIMIT >"$D/limit.json"
printf 'main\t%s\txray\tv\tf\t%s\n' "$D/main.json" "$D/tunnel-main.json" >"$D/manifest"
printf 'limit5\t%s\txray5\tv5\tf5\t%s\n' "$D/limit.json" "$D/tunnel-limit.json" >>"$D/manifest"
cat >"$D/bin/xray" <<'EOF'
#!/bin/sh
[ "${MOCK_FAIL:-0}" = 1 ] && exit 1
exit 0
EOF
chmod 755 "$D/bin/xray"
MPTCP_MANIFEST="$D/manifest" MPTCP_SUITE_DIR="$D/out" MPTCP_XRAY_BIN="$D/bin/xray" "$F" --apply | grep -Fq 'DIRECT_SNAPSHOT_OK count=2'
grep -qx MAIN "$D/out/direct-main.json"; grep -qx LIMIT "$D/out/direct-limit5.json"
[ "$(ls -l "$D/out/direct-main.json" | awk '{print $1}')" = '-rw-------' ]
echo DIRECT_SNAPSHOT_SUCCESS_OK
rm -f "$D/out/"*; set +e; out="$(MOCK_FAIL=1 MPTCP_MANIFEST="$D/manifest" MPTCP_SUITE_DIR="$D/out" MPTCP_XRAY_BIN="$D/bin/xray" "$F" --apply 2>&1)"; rc=$?; set -e
[ "$rc" -eq 5 ]; [ -z "$(find "$D/out" -type f -print)" ]; echo "$out" | grep -Fq ERROR=invalid_config:main
echo DIRECT_SNAPSHOT_VALIDATION_FAIL_OK
