#!/bin/sh
set -eu
G=luci-app-mptcp-suite/files/usr/libexec/mptcp-suite/tproxy-nft-generate
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
cat >"$D/uci" <<'MOCK'
#!/bin/sh
case "$*" in
 '-q show mptcp_profiles') printf 'mptcp_profiles.alpha=profile\nmptcp_profiles.beta=profile\n';;
 *alpha.enabled) echo 1;; *alpha.diversion_role) echo "${ROLE_A:-main}";; *alpha.server) echo "${SERVER_A:-203.0.113.10}";; *alpha.local_port) echo "${PORT_A:-23451}";;
 *beta.enabled) echo 1;; *beta.diversion_role) echo "${ROLE_B:-limited}";; *beta.server) echo "${SERVER_B:-203.0.113.10}";; *beta.local_port) echo "${PORT_B:-23452}";;
 *) exit 1;; esac
MOCK
chmod 755 "$D/uci"
run(){ env MPTCP_UCI_BIN="$D/uci" ROLE_A="${ROLE_A:-main}" ROLE_B="${ROLE_B:-limited}" SERVER_A="${SERVER_A:-203.0.113.10}" SERVER_B="${SERVER_B:-203.0.113.10}" PORT_A="${PORT_A:-23451}" PORT_B="${PORT_B:-23452}" "$G" "$D/out.nft"; }
run | grep -qx TPROXY_NFT_GENERATE_OK
grep -Fq '127.0.0.1:23451' "$D/out.nft"; grep -Fq '127.0.0.1:23452' "$D/out.nft"; grep -Fq 'Android-connectivity' "$D/out.nft"
set +e; O="$(ROLE_B=main run 2>&1)"; R=$?; set -e; [ "$R" -eq 3 ]; [ "$O" = ERROR=duplicate_main_role ]
set +e; O="$(ROLE_A=none run 2>&1)"; R=$?; set -e; [ "$R" -eq 6 ]; [ "$O" = ERROR=main_role_missing ]
set +e; O="$(SERVER_B=203.0.113.9 run 2>&1)"; R=$?; set -e; [ "$R" -eq 9 ]; [ "$O" = ERROR=server_mismatch ]
set +e; O="$(PORT_B=23451 run 2>&1)"; R=$?; set -e; [ "$R" -eq 11 ]; [ "$O" = ERROR=duplicate_local_port ]
echo TPROXY_ROLE_GENERATOR_TEST_OK
