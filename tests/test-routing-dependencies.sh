#!/bin/sh
set -eu
M=mptcp-suite-routing/Makefile
grep -Fq "+curl" "$M"
grep -Fq "+ip-full" "$M"
grep -Fq "+jsonfilter" "$M"
echo ROUTING_DEPENDENCIES_OK
