#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/usr/libexec/rpcd/mptcp-restore
grep -Fq 'SNAPLIST="/tmp/mptcp-restore-snapshot-$$"' "$F"
grep -Fq '[ -e "/usr/libexec/rpcd/xray-manager" ]' "$F"
grep -Fq 'tar -C / -czf "$snap" -T "$SNAPLIST"' "$F"
grep -Fq 'Gagal membuat snapshot sebelum restore' "$F"
echo OPTIONAL_RESTORE_SNAPSHOT_OK
