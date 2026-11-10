#!/bin/sh
set -eu
SRC="$PWD/mptcp-suite-core/files/usr/libexec/mptcp-suite/allocate"
D="$(mktemp -d)"
trap 'rm -rf "$D"' EXIT
mkdir -p "$D/bin"

cat >"$D/bin/ip" <<'MOCK'
#!/bin/sh
cat <<OUT
0: from all lookup local
98: from all fwmark 0x900 lookup 900
32766: from all lookup main
32767: from all lookup default
OUT
MOCK

cat >"$D/bin/ss" <<'MOCK'
#!/bin/sh
exit 0
MOCK

cat >"$D/bin/nft" <<'MOCK'
#!/bin/sh
exit 0
MOCK

chmod 755 "$D/bin/"*
PATH="$D/bin:$PATH"
export PATH

sh "$SRC" >"$D/result"

grep -qx 'primary_table=11001' "$D/result"
grep -qx 'primary_priority=101' "$D/result"
grep -qx 'secondary_priority=102' "$D/result"
grep -qx 'tproxy_priority=103' "$D/result"
grep -qx 'tproxy_mark=0x4A01' "$D/result"
grep -qx 'dns_port=12000' "$D/result"

echo ALLOCATE_DYNAMIC_PRIORITY_6_CHECKS_OK
