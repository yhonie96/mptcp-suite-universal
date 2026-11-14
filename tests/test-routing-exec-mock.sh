#!/bin/sh
set -eu
E=mptcp-suite-routing/files/usr/libexec/mptcp-suite/routing-exec
D="$(mktemp -d)"
trap 'rm -rf "$D" /tmp/mptcp-routing.lock /tmp/mptcp-routing.snapshot' EXIT
P="$D/plan"
printf '#!/bin/sh\necho DRY_RUN_OK\n' > "$P"
chmod 755 "$P"
OUT="$(MPTCP_ROUTING_PLAN_BIN="$P" MPTCP_PAUSED_FILE="$D/paused" "$E")"
[ "$OUT" = DRY_RUN_OK ]
echo ROUTING_EXEC_DRYRUN_OK
touch "$D/paused"
set +e
OUT="$(MPTCP_ROUTING_PLAN_BIN="$P" MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 3 ]
[ "$OUT" = ERROR=paused ]
echo ROUTING_EXEC_PAUSED_GUARD_OK
rm -f "$D/paused"
set +e
OUT="$(MPTCP_ROUTING_PLAN_BIN="$P" MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 4 ]
[ "$OUT" = ERROR=apply_locked ]
echo ROUTING_EXEC_APPLY_LOCK_OK
set +e
OUT="$(MPTCP_ROUTING_PLAN_BIN="$P" "$E" --invalid 2>&1)"
RC=$?
set -e
[ "$RC" -eq 1 ]
[ "$OUT" = ERROR=invalid_mode ]
echo ROUTING_EXEC_INVALID_MODE_OK
mkdir -p "$D/bin"
U="$D/bin/uci"
echo "#!/bin/sh" > "$U"
echo "for X do :; done" >> "$U"
echo "case \"\$X\" in" >> "$U"
echo "*.allocated) echo 0;;" >> "$U"
echo "*.primary_table) echo 11001;;" >> "$U"
echo "*.secondary_table) echo 11002;;" >> "$U"
echo "*.tproxy_table) echo 11003;;" >> "$U"
echo "*.primary_priority) echo 98;;" >> "$U"
echo "*.secondary_priority) echo 99;;" >> "$U"
echo "*.tproxy_priority) echo 100;;" >> "$U"
echo "*.bypass_mark) echo 0x4A02;;" >> "$U"
echo "*.policy_mark) echo 0x4A03;;" >> "$U"
echo "*.tproxy_mark) echo 0x4A01;;" >> "$U"
echo "*.bypass_mark) echo 0x4A02;;" >> "$U"
echo "*.policy_mark) echo 0x4A03;;" >> "$U"
echo "*.tproxy_mark) echo 0x4A01;;" >> "$U"
echo "esac" >> "$U"
chmod 755 "$U"
set +e
OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 6 ]
[ "$OUT" = ERROR=not_allocated ]
echo ROUTING_EXEC_NOT_ALLOCATED_OK
sed -i "s/*.allocated) echo 0/*.allocated) echo 1/" "$U"
sed -i "s/*.primary_table) echo 11001/*.primary_table) echo 0/" "$U"
set +e
OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 7 ]
[ "$OUT" = ERROR=table_id_range ]
echo ROUTING_EXEC_TABLE_RANGE_OK
sed -i "s/*.primary_table) echo 0/*.primary_table) echo 11002/" "$U"
set +e
OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 7 ]
[ "$OUT" = ERROR=duplicate_table_id ]
echo ROUTING_EXEC_DUPLICATE_TABLE_OK
sed -i "s/*.primary_table) echo 11002/*.primary_table) echo 11001/" "$U"
sed -i "s/*.primary_priority) echo 98/*.primary_priority) echo 0/" "$U"
set +e
OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 7 ]
[ "$OUT" = ERROR=priority_range ]
echo ROUTING_EXEC_PRIORITY_RANGE_OK
sed -i "s/*.primary_priority) echo 0/*.primary_priority) echo 99/" "$U"
set +e
OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"
RC=$?
set -e
[ "$RC" -eq 7 ]
[ "$OUT" = ERROR=duplicate_priorities ]
echo ROUTING_EXEC_DUPLICATE_PRIORITY_OK
sed -i "s/*.primary_priority) echo 99/*.primary_priority) echo 98/" "$U"
sed -i "s/*.bypass_mark) echo 0x4A02/*.bypass_mark) echo 0x4A03/" "$U"
set +e; OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"; RC=$?; set -e
[ "$RC" -eq 7 ]; [ "$OUT" = ERROR=duplicate_marks ]
echo ROUTING_EXEC_DUPLICATE_MARK_OK
sed -i "s/*.bypass_mark) echo 0x4A03/*.bypass_mark) echo 0x102/" "$U"
set +e; OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"; RC=$?; set -e
[ "$RC" -eq 7 ]; [ "$OUT" = ERROR=invalid_mark ]
echo ROUTING_EXEC_LEGACY_MARK_REJECT_OK
sed -i "s/*.bypass_mark) echo 0x102/*.bypass_mark) echo x123/" "$U"
set +e; OUT="$(PATH="$D/bin:$PATH" MPTCP_ROUTING_APPLY=1 MPTCP_PAUSED_FILE="$D/paused" "$E" --apply 2>&1)"; RC=$?; set -e
[ "$RC" -eq 7 ]; [ "$OUT" = ERROR=invalid_mark ]
echo ROUTING_EXEC_INVALID_MARK_FORMAT_OK
