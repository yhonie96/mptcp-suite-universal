#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-profile-list

sh -n "$F"
grep -Fq 'mptcp_profiles.$ID.enabled' "$F"
grep -Fq 'mptcp_profiles.$ID.config' "$F"
grep -Fq 'mptcp_profiles.$ID.service' "$F"
grep -Fq 'mptcp_profiles.$ID.outbound_tag' "$F"
grep -Fq 'mptcp_profiles.$ID.freedom_tag' "$F"
! grep -Eq 'main|limit5|xray-5mbps|12345|12346' "$F"

echo PROFILE_LIST_HELPER_OK
