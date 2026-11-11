#!/bin/sh
set -eu
test -f mptcp-suite-dual-xray/Makefile
grep -q 'PKG_NAME:=mptcp-suite-dual-xray' mptcp-suite-dual-xray/Makefile
test "$(find mptcp-suite-dual-xray/files -type f | wc -l)" = 0
echo PACKAGE_BOUNDARY_SKELETON_OK
