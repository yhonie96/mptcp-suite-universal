#!/bin/sh
set -eu
RPC=luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp
UI=luci-app-mptcp-suite/files/www/luci-static/resources/view/status/mptcp.js
grep -Fq 'json_add_int profile_count "$COUNT"' "$RPC"
grep -Fq 'Number(h.profile_count||0)===0' "$UI"
grep -Fq "actionAttrs.disabled=''" "$UI"
! grep -Fq "Aktivasi MPTCP Diblokir" "$UI"
grep -Fq "Aktifkan MPTCP" "$UI"
! grep -Fq 'Buat Profil Xray Dahulu' "$UI"
echo ZERO_PROFILE_DASHBOARD_OK
