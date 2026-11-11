OUT="$(sh mptcp-suite-routing/files/usr/libexec/mptcp-suite/failover-apply \
 FAILOVER eth1 192.168.8.1 7 phy0-sta0 192.168.1.1 9 102)"
echo "$OUT" | grep -Fq "table 102"
if echo "$OUT" | grep -Eq 'dev eth1 metric 7$'; then
 echo "ERROR=main_table_modified"
 exit 1
fi
echo FAILOVER_MAIN_TABLE_PRESERVED_OK
