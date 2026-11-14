#!/bin/sh
set -eu
I="${1:-./mptcp-suite-dual-xray/files/etc/uci-defaults/99-mptcp-xray-geodata}"
D="${TMPDIR:-/tmp}/dns-installer-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/config" "$D/bin" "$D/services" "$D/cron"
cat >"$D/config/dhcp" <<'EOF'
config dnsmasq
 option noresolv '0'
 list server '9.9.9.9'
EOF
cat >"$D/bin/uci" <<'EOF'
#!/bin/sh
exec uci "$@"
EOF
cat >"$D/bin/nslookup" <<'EOF'
#!/bin/sh
[ "${MOCK_DNS_FAIL:-0}" = 1 ] && exit 1
exit 0
EOF
for n in xray-dns dnsmasq cron; do
 cat >"$D/services/$n" <<'EOF'
#!/bin/sh
echo "${0##*/} $*" >>"$MOCK_LOG"
[ "${MOCK_FAIL_SERVICE:-}" = "${0##*/}" ] && [ "${1:-}" = restart ] && exit 1
[ "${1:-}" = enabled ] && exit "${MOCK_ENABLED_RC:-1}"
[ "${1:-}" = status ] && echo running
exit 0
EOF
 chmod 755 "$D/services/$n"
done
chmod 755 "$D/bin/uci" "$D/bin/nslookup"
run() {
 env MOCK_LOG="$D/actions.log" MOCK_FAIL_SERVICE="${MOCK_FAIL_SERVICE:-}" MOCK_DNS_FAIL="${MOCK_DNS_FAIL:-0}" \
 MPTCP_DNS_UCI="$D/bin/uci" MPTCP_DNS_UCI_DIR="$D/config" \
 MPTCP_DNS_CRON_FILE="$D/cron/root" MPTCP_DNS_XRAY_SERVICE="$D/services/xray-dns" \
 MPTCP_DNS_DNSMASQ_SERVICE="$D/services/dnsmasq" MPTCP_DNS_CRON_SERVICE="$D/services/cron" \
 MPTCP_DNS_NSLOOKUP="$D/bin/nslookup" MPTCP_DNS_BACKUP="$D/dhcp.backup" "$I"
}
: >"$D/actions.log"; run
[ "$(uci -c "$D/config" get dhcp.@dnsmasq[0].server | grep -o "127.0.0.1#1053" | wc -l)" -eq 1 ]
grep -Fq ".server='9.9.9.9'" <<EOF
$(uci -c "$D/config" show dhcp.@dnsmasq[0])
EOF
[ "$(grep -Fc update-xray-geodata "$D/cron/root")" -eq 1 ]
run
[ "$(uci -c "$D/config" get dhcp.@dnsmasq[0].server | grep -o "127.0.0.1#1053" | wc -l)" -eq 1 ]
[ "$(grep -Fc update-xray-geodata "$D/cron/root")" -eq 1 ]
echo XRAY_DNS_INSTALLER_IDEMPOTENT_OK
cp -p "$D/config/dhcp" "$D/good.dhcp"
set +e; MOCK_FAIL_SERVICE=xray-dns run >/dev/null 2>&1; rc=$?; set -e
[ "$rc" -ne 0 ]; cmp -s "$D/config/dhcp" "$D/good.dhcp"
[ "$(grep -Fc update-xray-geodata "$D/cron/root")" -eq 1 ]
grep -Fq "xray-dns disable" "$D/actions.log"
echo XRAY_DNS_XRAY_ROLLBACK_OK
set +e; MOCK_FAIL_SERVICE=dnsmasq run >/dev/null 2>&1; rc=$?; set -e
[ "$rc" -ne 0 ]; cmp -s "$D/config/dhcp" "$D/good.dhcp"
echo XRAY_DNS_DNSMASQ_ROLLBACK_OK
set +e; MOCK_DNS_FAIL=1 run >/dev/null 2>&1; rc=$?; set -e
[ "$rc" -ne 0 ]; cmp -s "$D/config/dhcp" "$D/good.dhcp"
echo XRAY_DNS_LOOKUP_ROLLBACK_OK
