#!/bin/sh
echo "$*" >>"$LOG"
[ "${UCI_FAIL:-}" = "$*" ] && exit 1
[ "${UCI_BAD_GET:-}" = "$*" ] && { echo BAD; exit 0; }
for X do LAST="$X"; done
case "$*" in
*" set "*) K="${LAST%%=*}"; V="${LAST#*=}"; K="${K##*.}"; sed -i "/^$K=/d" "$STATE"; echo "$K=$V" >>"$STATE";;
*" get "*) K="${LAST##*.}"; sed -n "s/^$K=//p" "$STATE";;
*" revert "*) : >"$STATE";;
esac
