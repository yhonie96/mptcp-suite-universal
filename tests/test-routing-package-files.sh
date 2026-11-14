#!/bin/sh
set -eu
M=mptcp-suite-routing/Makefile
grep -Fq '$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/*' "$M"
test -x mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-plan
test -x mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-plan
test -x mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-exec
test -x mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-restore
grep -Fq '$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/*' mptcp-suite-routing/Makefile
echo ROUTING_PACKAGE_FILES_OK
