#!/bin/sh
[ "${MOCK_IP_FAIL:-}" = "$*" ] && exit 1
[ "${MOCK_BAD_ROUTE:-0}" = 1 ] && [ "$*" = "route get 8.8.8.8 mark 0x4A01" ] && { echo "8.8.8.8 dev lo table 99999"; exit 0; }
echo "$*" >>"$LOG"
case "$*" in
"route show table 11001") echo "default via 10.0.0.1 dev eth9 metric 7";;
"route show table 11002") echo "default via 20.0.0.1 dev usb9 metric 9";;
"route show table 11003") echo "local default dev lo scope host";;
"route get 8.8.8.8 mark 0x4A02") echo "8.8.8.8 dev eth9 table 11001";;
"route get 8.8.8.8 mark 0x4A03") echo "8.8.8.8 dev usb9 table 11002";;
"route get 8.8.8.8 mark 0x4A01") echo "8.8.8.8 dev lo table 11003";;
esac
