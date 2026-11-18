#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/sbin/mptcp-activate
grep -Fq 'STAGE=diversion_generate' "$F"
grep -Fq '"$NFT_GENERATOR" "$NFT_FILE"' "$F"
grep -Fq 'STAGE=diversion_check' "$F"
echo ACTIVATE_GENERATOR_INTEGRATION_OK
