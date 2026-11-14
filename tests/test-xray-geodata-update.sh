#!/bin/sh
set -eu
U="${1:-./mptcp-suite-dual-xray/files/usr/bin/update-xray-geodata}"
D="${TMPDIR:-/tmp}/geodata-test-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin" "$D/asset" "$D/download" "$D/config" "$D/services" "$D/tmp"
printf OLD_GEOIP >"$D/asset/geoip.dat"
printf OLD_GEOSITE >"$D/asset/geosite.dat"
printf NEW_GEOIP >"$D/download/geoip.dat"
printf NEW_GEOSITE >"$D/download/geosite.dat"
sha256sum "$D/download/geoip.dat" >"$D/download/geoip.dat.sha256sum"
sha256sum "$D/download/geosite.dat" >"$D/download/geosite.dat.sha256sum"
for n in dns main limit5; do printf '{}\n' >"$D/config/$n.json"; done
cat >"$D/bin/curl" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ]; do case "$1" in -o) o="$2"; shift 2;; -*) shift;; *) u="$1"; shift;; esac; done
cp "$MOCK_DOWNLOAD/${u##*/}" "$o"
EOF
cat >"$D/bin/xray" <<'EOF'
#!/bin/sh
echo "XRAY $*" >>"$MOCK_LOG"
[ "${MOCK_XRAY_FAIL:-0}" = 1 ] && exit 1
exit 0
EOF
for n in dns main limit5; do
 cat >"$D/services/$n" <<'EOF'
#!/bin/sh
echo "SERVICE $0 $*" >>"$MOCK_LOG"
[ "${MOCK_SERVICE_FAIL:-}" = "${0##*/}" ] && exit 1
[ "${1:-}" = status ] && echo running
exit 0
EOF
 chmod 755 "$D/services/$n"
done
chmod 755 "$D/bin/curl" "$D/bin/xray"
run() {
 env MOCK_DOWNLOAD="$D/download" MOCK_LOG="$D/actions.log" \
 MOCK_XRAY_FAIL="${MOCK_XRAY_FAIL:-0}" MOCK_SERVICE_FAIL="${MOCK_SERVICE_FAIL:-}" \
 XRAY_GEODATA_MODE=apply XRAY_GEODATA_ASSET="$D/asset" \
 XRAY_GEODATA_TMP="$D/tmp" XRAY_GEODATA_LOG="$D/run.log" \
 XRAY_GEODATA_BASE=mock:// XRAY_GEODATA_CURL="$D/bin/curl" \
 XRAY_GEODATA_XRAY="$D/bin/xray" \
 XRAY_GEODATA_CONFIGS="$D/config/dns.json $D/config/main.json $D/config/limit5.json" \
 XRAY_GEODATA_SERVICES="$D/services/dns $D/services/main $D/services/limit5" \
 "$U"
}
: >"$D/actions.log"; run
grep -qx GEODATA_UPDATE_OK "$D/run.log"
grep -qx NEW_GEOIP "$D/asset/geoip.dat"
grep -qx NEW_GEOSITE "$D/asset/geosite.dat"
echo GEODATA_SUCCESS_OK
printf OLD_GEOIP >"$D/asset/geoip.dat"; printf OLD_GEOSITE >"$D/asset/geosite.dat"
printf bad >"$D/download/geosite.dat.sha256sum"
set +e; run; rc=$?; set -e
[ "$rc" -eq 2 ]
grep -qx OLD_GEOIP "$D/asset/geoip.dat"
grep -qx OLD_GEOSITE "$D/asset/geosite.dat"
echo GEODATA_CHECKSUM_FAIL_OK
sha256sum "$D/download/geosite.dat" >"$D/download/geosite.dat.sha256sum"
rm -f "$D/asset/geoip.dat" "$D/asset/geosite.dat"
run
grep -qx NEW_GEOIP "$D/asset/geoip.dat"
echo GEODATA_FRESH_INSTALL_OK
printf OLD_GEOIP >"$D/asset/geoip.dat"; printf OLD_GEOSITE >"$D/asset/geosite.dat"
set +e; MOCK_XRAY_FAIL=1 run; rc=$?; set -e
[ "$rc" -eq 4 ]
grep -qx OLD_GEOIP "$D/asset/geoip.dat"
grep -qx OLD_GEOSITE "$D/asset/geosite.dat"
echo GEODATA_CONFIG_ROLLBACK_OK
set +e; MOCK_SERVICE_FAIL=limit5 run; rc=$?; set -e
[ "$rc" -eq 6 ]
grep -qx OLD_GEOIP "$D/asset/geoip.dat"
grep -qx OLD_GEOSITE "$D/asset/geosite.dat"
echo GEODATA_SERVICE_ROLLBACK_OK
