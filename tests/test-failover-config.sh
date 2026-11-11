#!/bin/sh
set -eu
C=mptcp-suite-core/files/etc/config/mptcp_suite
grep -Fq "config failover 'failover'" "$C"
grep -Fq "option enabled '0'" "$C"
grep -Fq "option failure_threshold '3'" "$C"
grep -Fq "option recovery_threshold '3'" "$C"
echo FAILOVER_CONFIG_OK
