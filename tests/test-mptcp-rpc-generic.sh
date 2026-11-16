#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp

sh -n "$F"
"$F" list | jsonfilter -e '@.status' >/dev/null

grep -Fq 'mptcp-profile-backup' "$F"
grep -Fq 'mptcp-profile-restart' "$F"
grep -Fq 'tunnel-profiles.tsv' "$F"
grep -Fq 'cleanup_staged()' "$F"
grep -Fq 'restore_profiles()' "$F"
grep -Fq '[ "$COUNT" -gt 0 ] || XRAY=0' "$F"

! grep -Eq 'xray-5mbps|/etc/xray/config|MAIN=|LIMIT=|TMAIN=|TLIMIT=' "$F"

grep -Fq "check_http()" "$F"
grep -Fq "direct_http_not_ready" "$F"
grep -Fq "check_http >/dev/null" "$F"
grep -Fq "jeda tetap dipertahankan" "$F"
grep -Fq "disable_diversion()" "$F"
grep -Fq '"$NFT_BIN" delete table ip bsbf_bonding' "$F"
! grep -Fq "nft -f /usr/share/bsbf/bsbf_bonding.nft" "$F"
grep -Fq "transparent_diversion_unsafe" "$F"
! grep -Fq "Aktivasi diblokir: diversion transparan belum aman" "$F"
grep -Fq "mptcp-direct-snapshot" "$F"
grep -Fq "mptcp-resume-safe" "$F"
grep -Fq "mptcp-activate" "$F"
grep -Fq '"$DIRECT_SNAPSHOT" --apply' "$F"
grep -Fq '"$ACTIVATE" --apply' "$F"
grep -Fq "Aktivasi gagal; Direct dipertahankan" "$F"
grep -Fq "mode Direct darurat dipertahankan" "$F"
echo MPTCP_RPC_GENERIC_OK
