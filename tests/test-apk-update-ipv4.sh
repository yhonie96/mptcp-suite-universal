#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/apk-update-ipv4
sh -n "$F"
grep -Fq "HOST=downloads.openwrt.org" "$F"
grep -Fq "trap" "$F"
grep -Fq "apk update" "$F"
! grep -Fq "apk upgrade" "$F"
echo APK_UPDATE_IPV4_HELPER_OK
