#!/bin/sh
set -eu
P=luci-app-mptcp-suite
test -f "$P/Makefile"
for F in  usr/libexec/rpcd/mptcp  usr/libexec/rpcd/xray-profiles  usr/libexec/rpcd/xray-profile-builder  usr/libexec/rpcd/xray-profile-runtime  www/luci-static/resources/view/status/mptcp.js  www/luci-static/resources/view/status/xray-profiles.js  etc/config/mptcp_profiles
do
 test -f "$P/files/$F"
done
test "$(awk 'NR==26{print substr($0,1,1)=="\t"}' "$P/Makefile")" = 1
for F in "$P"/files/usr/libexec/rpcd/* "$P"/files/usr/sbin/* "$P"/files/etc/init.d/*; do
 sh -n "$F"
 test -x "$F"
done
! grep -RqiE '103\.147|192\.168\.(1|8)\.|eth1|phy0-sta0|WAN1|wwan|BEGIN.*PRIVATE' "$P/files"
grep -q 'json_add_string uuid ""' mptcp-suite-dual-xray/files/usr/libexec/rpcd/xray-manager
grep -q 'json_add_string uuid ""' mptcp-suite-dual-xray/files/usr/libexec/rpcd/xray-5mbps-manager
echo LUCI_APP_MPTCP_SUITE_TEST_OK

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
cp -a "$P/files/." "$ROOT/"
chmod 600 "$ROOT/etc/config/mptcp_profiles"
test "$(find "$ROOT" -type f | wc -l)" = "$(find "$P/files" -type f | wc -l)"
test "$(ls -l "$ROOT/etc/config/mptcp_profiles" | awk '{print $1}')" = "-rw-------"
cp -a "$P/files/." "$ROOT/"
chmod 600 "$ROOT/etc/config/mptcp_profiles"
rm -rf "$ROOT/usr" "$ROOT/www" "$ROOT/etc/init.d" "$ROOT/etc/mptcp-suite"
test -f "$ROOT/etc/config/mptcp_profiles"
echo LUCI_APP_INSTALL_UPGRADE_UNINSTALL_OK

POLICY="mptcp-suite-dual-xray/files/usr/sbin/xray-policy-apply-draft"
grep -q '^HD=false$' "$POLICY"
grep -Fq '.domain[0]=="geosite:youtube"' "$POLICY"
grep -q '.outboundTag=$tunnel' "$POLICY"
grep -q '.network=="tcp" and .port=="80"' "$POLICY"
echo FULL_TUNNEL_POLICY_TEST_OK

AUTO="$P/files/etc/init.d/mptcp-autoreconnect"
grep -Fq '[ -e /etc/mptcp-suite/paused ]' "$AUTO"
grep -Fq 'reconnect boot dilewati' "$AUTO"
echo PAUSED_REBOOT_GUARD_TEST_OK

DASH="$P/files/www/luci-static/resources/view/status/mptcp.js"
grep -Fq "FULL TUNNEL VPS" "$DASH"
grep -Fq "DIRECT PER JALUR" "$DASH"
grep -Fq "activeSources+' aktif dari '" "$DASH"
grep -Fq "active?'Bonding'" "$DASH"
grep -Fq "Aktivasi MPTCP Diblokir" "$DASH"
! grep -Fq "resumeCheck" "$DASH"
! grep -Fq "resumeMptcp" "$DASH"
! grep -Fq "Memulihkan tunnel..." "$DASH"
! grep -Fq "Membentuk endpoint..." "$DASH"
! grep -Fq "Periksa & Aktifkan MPTCP" "$DASH"
grep -Fq "pauseMptcp" "$DASH"
! grep -Fq "Memeriksa internet..." "$DASH"
echo MODERN_DASHBOARD_TEST_OK

SETUP="$P/files/www/luci-static/resources/view/status/mptcp-setup.js"
grep -Fq 'Bonding semua jalur aktif' "$SETUP"
grep -Fq 'Jalur utama + cadangan' "$SETUP"
grep -Fq "primaryWrap.style.display" "$SETUP"
grep -Fq 'setup-hero' "$SETUP"
grep -Fq "PERAN: '+role" "$SETUP"
grep -Fq 'height:46px' "$SETUP"
echo MODERN_SETUP_TEST_OK

SOURCE_UI="$P/files/www/luci-static/resources/view/status/mptcp-source-editor.js"
grep -Fq 'Atur sumber koneksi dengan aman' "$SOURCE_UI"
grep -Fq 'DIDUKUNG' "$SOURCE_UI"
grep -Fq 'BELUM TERDETEKSI' "$SOURCE_UI"
grep -Fq 'Tidak ada draft perubahan.' "$SOURCE_UI"
grep -Fq 'Rollback otomatis' "$SOURCE_UI"
echo MODERN_SOURCE_EDITOR_TEST_OK

XP="$P/files/www/luci-static/resources/view/status/xray-profiles.js"
grep -Fq 'linear-gradient(135deg,#4338ca,#2563eb)' "$XP"
grep -Fq 'xp-wizard,.xp-card' "$XP"
grep -Fq 'height:44px' "$XP"
! grep -Fq 'Hapus Profil (Dilindungi)' "$XP"
! grep -Fq "p.id==='main'" "$XP"
! grep -Fq "p.id==='limit5'" "$XP"
echo MODERN_XRAY_PROFILES_TEST_OK

BACKUP_UI="$P/files/www/luci-static/resources/view/status/mptcp-backup.js"
grep -Fq 'linear-gradient(135deg,#4338ca,#2563eb)' "$BACKUP_UI"
grep -Fq 'backup-create' "$BACKUP_UI"
grep -Fq 'Restore Aman' "$BACKUP_UI"
grep -Fq 'Restore UI/BSBF' "$BACKUP_UI"
grep -Fq 'izin file 600' "$BACKUP_UI"
echo MODERN_BACKUP_UI_TEST_OK
R="$P/files/usr/sbin/bsbf-endpoint-repair"
test "$(grep -c paused "$R")" -ge 2
S="$P/files/etc/init.d/bsbf-endpoint-repair"
test "$(grep -c paused "$S")" -ge 1
echo ENDPOINT_PAUSED_GUARD_OK
grep -Fq "mptcp-reconnect || exit 1" "$AUTO"
