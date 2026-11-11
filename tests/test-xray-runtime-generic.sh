#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/libexec/rpcd/xray-profile-runtime

grep -Fq 'profile_count' "$F"
grep -Fq 'invalid_count' "$F"
grep -Fq 'uci -q show mptcp_profiles' "$F"
! grep -Eq 'main_valid|limit5_valid|/etc/xray-5mbps/config.json' "$F"
echo XRAY_DYNAMIC_SELF_TEST_OK
