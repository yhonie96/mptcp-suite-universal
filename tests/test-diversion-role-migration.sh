#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/etc/uci-defaults/98-mptcp-diversion-roles
sh -n "$F"
grep -Fq "main.diversion_role='main'" "$F"
grep -Fq "limit5.diversion_role='limited'" "$F"
grep -Fq 'uci commit mptcp_profiles' "$F"
echo DIVERSION_ROLE_MIGRATION_TEST_OK
