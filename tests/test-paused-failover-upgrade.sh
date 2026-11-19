#!/bin/sh
set -eu
F=mptcp-suite-routing/files/etc/uci-defaults/98-mptcp-paused-failover
D="$(mktemp -d)"; trap 'rm -rf "$D"' EXIT INT TERM
cat >"$D/uci" <<'MOCK'
#!/bin/sh
DB="${MOCK_DB:?}"
[ "${1:-}" = -q ] && shift
cmd="$1"; shift
case "$cmd" in
 get)
  key="$1"
  case "$key" in
   mptcp_suite.failover) echo failover;;
   *) grep -F "${key#*.failover.}=" "$DB" 2>/dev/null | tail -n1 | cut -d= -f2- || exit 1;;
  esac
 ;;
 set)
  pair="$1"; key="${pair%%=*}"; val="${pair#*=}"; name="${key#*.failover.}"
  grep -v "^$name=" "$DB" >"$DB.tmp" || true
  printf '%s=%s\n' "$name" "$val" >>"$DB.tmp"; mv "$DB.tmp" "$DB"
 ;;
 commit) echo commit >>"$MOCK_LOG";;
 *) exit 1;;
esac
MOCK
chmod 755 "$D/uci"
run(){ PATH="$D:$PATH" MOCK_DB="$D/db" MOCK_LOG="$D/log" sh "$F"; }
# Upgrade missing fields: add defaults but preserve enabled=0
printf 'enabled=0\n' >"$D/db"; : >"$D/log"; run
grep -qx primary_interface=WAN1 "$D/db"; grep -qx secondary_interface=wwan "$D/db"; grep -qx interval=10 "$D/db"; grep -qx enabled=0 "$D/db"; [ "$(grep -c '^commit$' "$D/log")" -eq 1 ]
# Existing custom values: never overwrite and do not commit
printf 'enabled=1\nprimary_interface=wanA\nsecondary_interface=wanB\ninterval=30\n' >"$D/db"; : >"$D/log"; run
grep -qx primary_interface=wanA "$D/db"; grep -qx secondary_interface=wanB "$D/db"; grep -qx interval=30 "$D/db"; grep -qx enabled=1 "$D/db"; [ ! -s "$D/log" ]
echo PAUSED_FAILOVER_UPGRADE_V5_OK
