#!/bin/sh
set -eu
P=mptcp-suite-core/files/usr/libexec/mptcp-suite/apply-limits
D="$(mktemp -d)"
trap 'rm -rf "$D"' EXIT
printf '#!/bin/sh\ncase "$*" in *subflows*) echo "${TEST_S:-8}";; *) echo "${TEST_A:-8}";; esac\n' >"$D/uci"
printf '#!/bin/sh\nprintf "%%s\n" "$*" >"$OUT"\n' >"$D/ip"
chmod 755 "$D/uci" "$D/ip"
OUT="$D/result" PATH="$D:$PATH" "$P"
grep -Fxq "mptcp limits set subflows 8 add_addr_accepted 8" "$D/result"
rm -f "$D/result"
! TEST_S=x OUT="$D/result" PATH="$D:$PATH" "$P"
[ ! -e "$D/result" ]
echo APPLY_LIMITS_MOCK_OK
