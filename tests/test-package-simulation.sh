#!/bin/sh
set -eu
U=luci-app-mptcp-suite/files
D=mptcp-suite-dual-xray/files
! find "$U" -type f | grep -Eq "xray-5mbps-manager|xray-manager.js|xray-traffic-rules|xray-policy-apply-draft"
! grep -Eq "config profile|12345|12346|3443|3444" "$U/etc/config/mptcp_profiles"
for F in etc/init.d/xray-5mbps usr/libexec/rpcd/xray-manager usr/libexec/rpcd/xray-5mbps-manager usr/libexec/rpcd/xray-traffic-rules; do test -f "$D/$F"; done
echo PACKAGE_SIMULATION_OK
