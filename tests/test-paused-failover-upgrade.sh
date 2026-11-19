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
# Upgrade missing interval: add only interval and preserve enabled=0
printf 'enabled=0\n' >"$D/db"; : >"$D/log"; run
grep -qx interval=10 "$D/db"; grep -qx probe_ip_primary=1.1.1.1 "$D/db"; grep -qx probe_ip_secondary=8.8.8.8 "$D/db"; grep -qx enabled=0 "$D/db"; ! grep -q 'interface=' "$D/db"; [ "$(grep -c '^commit$' "$D/log")" -eq 1 ]
# Existing custom values: never overwrite and do not commit
printf 'enabled=1\nprimary_interface=uplink_x\nsecondary_interface=uplink_y\ninterval=30\nprobe_ip_primary=9.9.9.9\nprobe_ip_secondary=149.112.112.112\n' >"$D/db"; : >"$D/log"; run
grep -qx primary_interface=uplink_x "$D/db"; grep -qx secondary_interface=uplink_y "$D/db"; grep -qx interval=30 "$D/db"; grep -qx probe_ip_primary=9.9.9.9 "$D/db"; grep -qx probe_ip_secondary=149.112.112.112 "$D/db"; grep -qx enabled=1 "$D/db"; [ ! -s "$D/log" ]
echo PAUSED_FAILOVER_HARDCODE_FIX_V6_OK
