#!/bin/sh
set -eu
W=.github/workflows/build.yml
grep -Fq "mptcp-suite-dual-xray" "$W"
grep -Fq "bin/packages/**/*.apk" "$W"
test -f mptcp-suite-dual-xray/Makefile
echo BUILD_WORKFLOW_DUAL_XRAY_OK
