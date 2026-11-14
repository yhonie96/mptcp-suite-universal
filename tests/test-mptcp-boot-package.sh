#!/bin/sh
set -eu
I=luci-app-mptcp-suite/files/etc/init.d/mptcp-suite-boot
C=luci-app-mptcp-suite/files/etc/uci-defaults/99-mptcp-suite-boot
test -x "$I"
test -x "$C"
sh -n "$I"
sh -n "$C"
grep -Fq "mptcp-suite-boot enable" "$C"
echo MPTCP_BOOT_PACKAGE_OK
