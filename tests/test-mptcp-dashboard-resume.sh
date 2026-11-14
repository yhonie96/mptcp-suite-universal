#!/bin/sh
set -eu
F="${1:-./luci-app-mptcp-suite/files/www/luci-static/resources/view/status/mptcp.js}"
grep -Fq "method:'resume_check'" "$F"
grep -Fq "method:'resume'" "$F"
grep -Fq 'Aktifkan MPTCP' "$F"
grep -Fq 'resumeCheck()' "$F"
grep -Fq 'resumeMptcp()' "$F"
! grep -Fq 'Aktivasi MPTCP Diblokir' "$F"
echo MPTCP_DASHBOARD_RESUME_OK
