#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/etc/config/mptcp_profiles
grep -Fq 'Profil Xray dibuat' "$F"
! grep -Eq 'config profile|main|limit5|12345|12346|3443|3444' "$F"
grep -Fq '/etc/config/mptcp_profiles' luci-app-mptcp-suite/Makefile
echo EMPTY_PROFILE_TEMPLATE_OK
