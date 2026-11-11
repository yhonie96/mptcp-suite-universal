#!/bin/sh
set -eu
P=mptcp-suite-core/files/usr/libexec/mptcp-suite/main-gateway
J='{"route":[{"target":"0.0.0.0","mask":0,"nexthop":"10.0.0.9","table":102},{"target":"0.0.0.0","mask":0,"nexthop":"10.0.0.1"}]}'
[ "$(printf '%s\n' "$J" | "$P")" = "10.0.0.1" ]
! printf '%s\n' '{"route":[]}' | "$P" >/dev/null 2>&1
echo MAIN_GATEWAY_PARSER_OK
