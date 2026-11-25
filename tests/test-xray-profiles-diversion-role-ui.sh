#!/bin/sh
set -eu
F=luci-app-mptcp-suite/files/www/luci-static/resources/view/status/xray-profiles.js
grep -Fq "'limit_label','diversion_role'" "$F"
grep -Fq "selectField('Peran trafik','xp-role'" "$F"
grep -Fq "['none','Tidak dialihkan']" "$F"
grep -Fq "['main','Utama']" "$F"
grep -Fq "['limited','Terbatas']" "$F"
grep -Fq "val('xp-limit'),val('xp-role')" "$F"
grep -Fq "p.diversion_role||'Tidak dialihkan'" "$F"
echo XRAY_PROFILES_DIVERSION_ROLE_UI_OK
