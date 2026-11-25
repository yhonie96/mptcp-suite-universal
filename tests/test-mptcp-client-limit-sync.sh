#!/bin/sh
set -eu
S=./luci-app-mptcp-suite/files/usr/sbin/mptcp-client-limit-sync
D="${TMPDIR:-/tmp}/mptcp-limit-sync-$$"
trap 'rm -rf "$D"' EXIT INT TERM
mkdir -p "$D/bin"

cat >"$D/leases" <<'L'
1700000000 aa:bb:cc:dd:ee:01 192.168.10.21 host1 *
1700000000 aa:bb:cc:dd:ee:02 10.20.30.42 host2 *
1700000000 aa:bb:cc:dd:ee:03 192.168.10.23 host3 *
1700000000 aa:bb:cc:dd:ee:04 192.168.10.24 host4 *
L

cat >"$D/bin/nft" <<'MOCK'
#!/bin/sh
echo "nft $*" >>"$MOCK_LOG"
exit 0
MOCK

cat >"$D/bin/ip" <<'MOCK'
#!/bin/sh
exit 0
MOCK

cat >"$D/bin/uci" <<'MOCK'
#!/bin/sh
case "$*" in
 "-q show netcontrol")
  printf 'netcontrol.dev1=device\nnetcontrol.dev2=device\nnetcontrol.dev3=device\nnetcontrol.dev4=device\n'
  ;;
 "-q show mptcp_profiles")
  printf 'mptcp_profiles.main=profile\nmptcp_profiles.limit5=profile\n'
  ;;
 "-q get mptcp_profiles.limit5.enabled") echo 1 ;;
 "-q get mptcp_profiles.limit5.limit_label") echo "Limit 5 Mbps" ;;
 "-q get mptcp_profiles.limit5.diversion_role") echo "limited" ;;
 "-q get netcontrol.dev1.enabled") echo 1 ;;
 "-q get netcontrol.dev1.mac") echo "aa:bb:cc:dd:ee:01" ;;
 "-q get netcontrol.dev1.xray_profile") echo "limit5" ;;
 "-q get netcontrol.dev2.enabled") echo 1 ;;
 "-q get netcontrol.dev2.mac") echo "aa:bb:cc:dd:ee:02" ;;
 "-q get netcontrol.dev2.xray_profile") echo "auto" ;;
 "-q get netcontrol.dev2.download_kbps") echo 3000 ;;
 "-q get netcontrol.dev2.upload_kbps") echo 1000 ;;
 "-q get netcontrol.dev3.enabled") echo 1 ;;
 "-q get netcontrol.dev3.protected") echo 1 ;;
 "-q get netcontrol.dev3.mac") echo "aa:bb:cc:dd:ee:03" ;;
 "-q get netcontrol.dev3.xray_profile") echo "limit5" ;;
 "-q get netcontrol.dev4.enabled") echo 1 ;;
 "-q get netcontrol.dev4.override_until") echo 2000000000 ;;
 "-q get netcontrol.dev4.mac") echo "aa:bb:cc:dd:ee:04" ;;
 "-q get netcontrol.dev4.xray_profile") echo "limit5" ;;
 *) echo 0 ;;
esac
MOCK
chmod 755 "$D/bin/nft" "$D/bin/ip" "$D/bin/uci"

run() {
 env MOCK_LOG="$D/log" MPTCP_NFT_BIN="$D/bin/nft" MPTCP_UCI_BIN="$D/bin/uci" \
  MPTCP_IP_BIN="$D/bin/ip" MPTCP_LEASES_FILE="$D/leases" \
  MPTCP_PAUSED_FILE="$D/paused" MPTCP_NOW_EPOCH=1700000000 "$S"
}

: >"$D/log"; touch "$D/paused"
run
[ ! -s "$D/log" ]

rm -f "$D/paused"; : >"$D/log"
run
grep -qx 'nft flush set ip mptcp_tproxy limited_clients' "$D/log"
grep -qx 'nft add element ip mptcp_tproxy limited_clients { 192.168.10.21 }' "$D/log"
grep -qx 'nft add element ip mptcp_tproxy limited_clients { 10.20.30.42 }' "$D/log"
! grep -Fq '192.168.10.23' "$D/log"
! grep -Fq '192.168.10.24' "$D/log"
echo CLIENT_LIMIT_SYNC_ALL_OK
