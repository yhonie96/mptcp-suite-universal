#!/bin/sh
[ "${MOCK_IP_FAIL:-}" = "$*" ] && exit 1
[ "${MOCK_IP_MISSING:-}" = "$*" ] && { echo "Error: ipv4: FIB table does not exist." >&2; echo "Dump terminated" >&2; exit 2; }
[ "${MOCK_BAD_ROUTE:-0}" = 1 ] && [ "$*" = "route get 8.8.8.8 mark 0x4A01" ] && { echo "8.8.8.8 dev lo table 99999"; exit 0; }
echo "$*" >>"$LOG"
case "$*" in
"route show table 11001") echo "default via 10.0.0.1 dev eth9 metric 7";;
"route show table 11002") echo "default via 20.0.0.1 dev usb9 metric 9";;
"route show table 11003") echo "local default dev lo scope host";;
"rule show") printf "98:  from all fwmark 0x4A02 lookup 11001\040\n99: from all fwmark 0x4A03 lookup 11002\n100: from all fwmark 0x4A01 lookup 11003\040\n";;
"route get 8.8.8.8 mark 0x4A02") echo "8.8.8.8 dev eth9 table 11001";;
"route get 8.8.8.8 mark 0x4A03") echo "8.8.8.8 dev usb9 table 11002";;
"route get 8.8.8.8 mark 0x4A01") echo "8.8.8.8 dev lo table 11003";;
esac
