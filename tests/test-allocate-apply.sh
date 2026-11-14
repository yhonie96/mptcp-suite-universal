#!/bin/sh
set -eu
F=mptcp-suite-core/files/usr/libexec/mptcp-suite/allocate-apply
test -x "$F"
grep -Fq "allocated=1" "$F"
grep -Fq "MPTCP_ALLOCATE_BIN" "$F"
grep -Fq "MPTCP_ALLOCATE_CONFIG" "$F"
grep -Fq "ERROR=unsafe_allocation" "$F"
grep -Fq "uci -c" "$F"
grep -Fq "uci commit mptcp_suite" "$F"
D="$(mktemp -d)"
trap 'rm -rf "$D"' EXIT
mkdir "$D/bin" "$D/cfg"
cat >"$D/alloc" <<'OUT'
#!/bin/sh
cat <<'DATA'
primary_table=11001
secondary_table=11002
tproxy_table=11003
tproxy_mark=0x4A01
bypass_mark=0x4A02
policy_mark=0x4A03
primary_priority=104
secondary_priority=105
tproxy_priority=106
dns_port=12000
main_port=12001
limited_port=12002
DATA
OUT
chmod 755 "$D/alloc"
LOG="$D/uci.log"; export LOG
cat >"$D/bin/uci" <<'MOCK'
#!/bin/sh
echo "$*" >>"$LOG"
[ "${UCI_FAIL:-}" = "$*" ] && exit 1
exit 0
MOCK
chmod 755 "$D/bin/uci"
export PATH="$D/bin:$PATH"
set +e
OUT="$(MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"
RC=$?
set -e
[ "$RC" -eq 3 ]
[ "$OUT" = ERROR=apply_locked ]
test ! -s "$LOG"
grep -Fq "validate_allocation()" "$F"
grep -Fq "ERROR=duplicate_key" "$F"
grep -Fq "ERROR=missing_key" "$F"
! grep -Eq "eval|source|\. \"" "$F"
grep -Fq "validate_values()" "$F"
grep -Fq "ERROR=invalid_value" "$F"
grep -Fq "ERROR=duplicate_value" "$F"
grep -Fq "MPTCP_ALLOCATE_APPLY" "$F"
grep -Fq "apply_values()" "$F"
grep -Fq "ERROR=apply_locked" "$F"
echo ALLOCATE_APPLY_LOCKED_OK
sed -i "s/secondary_table=11002/secondary_table=11001/" "$D/alloc"
: >"$LOG"
set +e
OUT="$(MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"
RC=$?
set -e
[ "$RC" -eq 2 ]
[ "$OUT" = ERROR=duplicate_value ]
test ! -s "$LOG"
echo ALLOCATE_DUPLICATE_VALUE_REJECT_OK
sed -i "s/secondary_table=11001/secondary_table=11002/" "$D/alloc"
sed -i "s/dns_port=12000/dns_port=70000/" "$D/alloc"
: >"$LOG"
set +e; OUT="$(MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"; RC=$?; set -e
[ "$RC" -eq 2 ]; [ "$OUT" = ERROR=invalid_value ]; test ! -s "$LOG"
echo ALLOCATE_INVALID_VALUE_REJECT_OK
sed -i "s/dns_port=70000/dns_port=12000/" "$D/alloc"
sed -i "/^DATA/i evil_key=reboot" "$D/alloc"
: >"$LOG"
set +e; OUT="$(MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"; RC=$?; set -e
[ "$RC" -eq 2 ]; [ "$OUT" = ERROR=unsafe_allocation ]; test ! -s "$LOG"
echo ALLOCATE_UNSAFE_KEY_REJECT_OK
sed -i "/evil_key=/d" "$D/alloc"
sed -i "/^DATA/i primary_table=12000" "$D/alloc"
: >"$LOG"
set +e; OUT="$(MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"; RC=$?; set -e
[ "$RC" -eq 2 ]; [ "$OUT" = ERROR=duplicate_key ]; test ! -s "$LOG"
echo ALLOCATE_DUPLICATE_KEY_REJECT_OK
sed -i "/primary_table=12000/d" "$D/alloc"
sed -i "/^limited_port=12002$/d" "$D/alloc"
: >"$LOG"
set +e; OUT="$(MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"; RC=$?; set -e
[ "$RC" -eq 2 ]; [ "$OUT" = ERROR=missing_key ]; test ! -s "$LOG"
echo ALLOCATE_MISSING_KEY_REJECT_OK
sed -i "/primary_table=12000/d" "$D/alloc"
sed -i "/^DATA/i limited_port=12002" "$D/alloc"
: >"$LOG"
OUT="$(MPTCP_ALLOCATE_APPLY=1 MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F")"
[ "$OUT" = ALLOCATION_APPLY_OK ]
[ "$(wc -l < "$LOG")" -eq 14 ]
[ "$(tail -n 2 "$LOG" | head -n 1)" = "-c $D/cfg set mptcp_suite.routing.allocated=1" ]
[ "$(tail -n 1 "$LOG")" = "-c $D/cfg commit mptcp_suite" ]
echo ALLOCATE_APPLY_MOCK_OK
sed -i "/^limited_port=12002$/d" "$D/alloc"
sed -i "/^DATA/i limited_port=12002" "$D/alloc"
: >"$LOG"; export UCI_FAIL="-c $D/cfg set mptcp_suite.routing.policy_mark=0x4A03"
set +e; OUT="$(MPTCP_ALLOCATE_APPLY=1 MPTCP_ALLOCATE_BIN="$D/alloc" MPTCP_ALLOCATE_CONFIG="$D/cfg" "$F" 2>&1)"; RC=$?; set -e; unset UCI_FAIL
[ "$RC" -eq 4 ]; [ "$OUT" = ERROR=apply_failed ]
grep -Fq "revert mptcp_suite" "$LOG"
! grep -Fq "allocated=1" "$LOG"; ! grep -Fq "commit mptcp_suite" "$LOG"
echo ALLOCATE_APPLY_ROLLBACK_OK
