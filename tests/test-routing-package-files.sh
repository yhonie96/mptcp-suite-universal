#!/bin/sh
set -eu
M=mptcp-suite-routing/Makefile
grep -Fq '$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/*' "$M"
test -x mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-plan
test -x mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-plan
echo ROUTING_PACKAGE_FILES_OK
