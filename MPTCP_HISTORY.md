
### validation fix started Mon Nov 16 23:41:19 WIB 2026

### validation fix verified Mon Nov 16 23:44:20 WIB 2026
57 tests passed, HTTP 204 and subflow >=2 now required. Runtime unchanged. Not committed.

### validation fix commit Mon Nov 16 23:44:41 WIB 2026
commit_rc=0

### Pause managed-clear baseline Tue Nov 17 00:42:25 WIB 2026
Branch fix/pause-managed-clear at e045464. 56 tests passed. Runtime unchanged.

### Managed routing cleanup commit Tue Nov 17 00:52:40 WIB 2026
commit_rc=0; 57 tests passed; runtime unchanged.

### Pause cleanup integration Tue Nov 17 01:11:08 WIB 2026
commit_rc=0; 58 tests passed; runtime unchanged.

### Paused runtime verified Tue Nov 17 06:16:39 WIB 2026
Installed ff7dada routing and LuCI packages. Managed rules 104-106 removed; tables 11001-11003 empty; applied=0; legacy and Tailscale rules preserved; bonding NFT absent; HTTP=204; adblock NXDOMAIN; no VPS 3443 connection. Do not Resume yet.

### Legacy profile metadata repaired Tue Nov 17 06:23:56 WIB 2026
Recovered main/limit5 server=103.147.32.114 from trusted pre-66c583d tunnel snapshots; ports 3443/3444 matched UCI; HTTP=204; runtime remains paused/Direct.

### Role-based TPROXY generator Wed Nov 18 20:40:06 WIB 2026
commit_rc=0; 62 tests passed; generated NFT passed nft -c; baseline 2b041dce semantics preserved; VLESS Reality credentials unchanged; runtime remains paused/Direct.

### Runtime 8853964 verified Wed Nov 18 22:10:50 WIB 2026
LuCI installed; diversion roles main/limited migrated; generated NFT passed nft -c; bonding table remained absent; HTTP=204; VLESS Reality config hashes unchanged; router remains paused/Direct. Do not Resume yet.

### Live cycle 8853964 passed Wed Nov 18 22:18:41 WIB 2026
Resume succeeded: HTTP=204, endpoint=2, subflow=2, routing applied=1, NFT generated and loaded, VLESS Reality connected to 103.147.32.114:3443 on both WANs. Pause succeeded: HTTP=204, endpoint=0, subflow=0, applied=0, rules 104-106 removed, NFT absent, legacy/Tailscale preserved. Router left paused/Direct. Limited set remained empty and requires separate device test.

### VPS expired Wed Nov 18 22:22:19 WIB 2026
VPS 103.147.32.114 expired. Router remains paused/Direct. Do not Resume until new VLESS Reality profiles are configured and validated.

### Before paused failover v5 Thu Nov 19 11:54:45 WIB 2026
Failover otomatis belum tersedia. Bundle v1-v4 ditolak sebelum commit/runtime karena risiko state, file asing, parser rollback, dan migrasi upgrade. Tidak ada WAN/route runtime yang diubah. Kandidat v5: paused-only, threshold 3/3, rollback transaksional, state aman, migrasi UCI idempotent. Failover tetap disabled.

### Paused failover monitor committed Thu Nov 19 11:59:40 WIB 2026
commit_rc=0; 66 tests passed; default disabled; no autostart; dry-run preserved routes; rollback parses proto static; UCI migration preserves custom values. Runtime unchanged and paused/Direct.

### Test Core hardcode failure Thu Nov 19 12:08:25 WIB 2026
Commit 78d3ddf gagal Test Core karena WAN1/wwan tertanam pada default failover. Artifact 78d3ddf dilarang dipakai. Kandidat v6 menghapus hardcode, memakai fallback core.primary_wan/core.secondary_wan, dan migrasi hanya menambah interval=10 tanpa mengubah enabled. Runtime tetap paused/Direct; failover disabled.


### Failover hardcode fixed Thu Nov 19 12:12:52 WIB 2026
commit=edc178e; commit_rc=0; 67 tests passed; WAN1/wwan removed from production defaults; monitor falls back to core WAN allocation; migration only adds interval=10; runtime remains paused/Direct; failover disabled.

### Legacy automation cleanup Thu Nov 19 12:20:38 WIB 2026
Removed netcontrol-new-device-monitor cron; archived inactive duplicate Xray init script. Cron backup=/root/crontab.pre-cleanup. NetControl enforcement, DHCP paused guard, bsbf packages, and MPTCP Suite services retained. Router remains paused/Direct.

### Failover install autostart issue Thu Nov 19 13:30:57 WIB 2026
Artifact edc178e matched repo. Package install started paused-failover monitor although service and failover were disabled. Monitor was stopped; routes remained 7/9; paused=0; HTTP=204. Do not enable failover. Repo requires start_service enabled guard.

### Failover autostart fix v7 Thu Nov 19 13:34:17 WIB 2026
Artifact edc178e started the monitor after package reinstall although failover and service were disabled. Monitor was stopped safely; routes stayed metric 7/9; paused/Direct and HTTP=204 remained healthy. Candidate v7 adds start_service guards requiring failover.enabled=1 and paused marker before opening procd. Bundle SHA256=9787e2c618cdd74246f3690afcf22206110344de1126b58d3d38d13690bd8db9. Do not reuse artifact edc178e.

### Failover autostart fix v7 Thu Nov 19 13:34:53 WIB 2026
Artifact edc178e sempat menjalankan monitor saat failover disabled. Monitor dihentikan aman; route tetap 7/9; paused/Direct dan HTTP=204. V7 menambah guard enabled=1 dan marker paused sebelum procd dibuka. SHA256=9787e2c618cdd74246f3690afcf22206110344de1126b58d3d38d13690bd8db9.

### Failover startup guard committed Thu Nov 19 13:36:50 WIB 2026
commit_rc=0; 68 tests passed; procd starts only when failover enabled=1 and paused marker exists. Monitor runtime remained stopped; routes unchanged.

### Melolo adblock trial Thu Nov 19 13:59:10 WIB 2026
Blocked api16-access-wf-my.pangle.io and configure-tcp.rayjump.com via dnsmasq. Both resolve to 0.0.0.0/::; dnsmasq healthy; HTTP=204. Awaiting Melolo playback test.

### Melolo adblock stage 2 Thu Nov 19 14:26:48 WIB 2026
Added mediation-sg2-log.pangle.io, telemetry.sdk.inmobi.com, config.inmobi.com, and ms.applovin.com. DNS block verified; HTTP=204. Awaiting playback test.

### Melolo adblock stage 3 Thu Nov 19 14:40:03 WIB 2026
Added prod-mediate-events.applovin.com, sdkapi.dsp-api.moloco.com, api.ad.intl.xiaomi.com, and unif-id.ssp.inmobi.com. DNS block verified; HTTP=204. Awaiting playback test.

### Melolo adblock stage 4 Thu Nov 19 14:47:16 WIB 2026
Added six backup ad endpoints for AppLovin, Moloco, and Pangle. DNS block verified; HTTP=204. Total blocked domains=16. Awaiting playback test.

### Melolo adblock stage 5 Thu Nov 19 14:54:23 WIB 2026
Added sts.applovin.com, api16-access-ttp.tiktokpangle.us, cdn.liftoff-creatives.io, and logs.ads.vungle.com. DNS verified; HTTP=204. Total blocked domains=20. Awaiting playback test.

### Runtime 0feb05e startup guard verified Thu Nov 19 18:17:53 WIB 2026
Routing APK reinstall passed; disabled failover created no monitor process; service remained disabled; routes stayed metric 7/9; router remained paused/Direct; HTTP=204.

### Disabled failover guard passed Thu Nov 19 18:20:00 WIB 2026
Manual service start while failover=0 created no monitor process; routes remained metric 7/9; HTTP=204; router remained paused/Direct.

### Dual-WAN health passed Thu Nov 19 18:21:32 WIB 2026
eth1 HTTP=204 time=0.267s; phy0-sta0 HTTP=204 time=0.100s. Failover remained disabled; monitor stopped; routes unchanged at metrics 7/9.

### Manual failover transaction passed Thu Nov 19 18:22:49 WIB 2026
FAILOVER moved default route to phy0-sta0 and returned HTTP=204. RESTORE returned primary eth1; HTTP=204. Final routes restored to metrics 7/9. SSH LAN remained connected. Daemon still disabled.

### Runtime failover mock passed Thu Nov 19 18:24:04 WIB 2026
Installed monitor passed mocked 3-failure failover and 3-success restore; rc=0. Real failover remained disabled; daemon stopped; routes stayed metric 7/9; HTTP=204.

### Automatic RTO test failed safely Thu Nov 19 18:47:13 WIB 2026
Two monitor instances appeared. Primary outage broke DNS-dependent probing, so healthy secondary was classified unhealthy; FC=4 and no failover occurred. Recovery completed: both WANs reach 1.1.1.1, Xray DNS resolves example.com, failover=0, monitor stopped, routes restored 7/9. Do not enable failover pending single-instance lock and DNS-independent probes.

### Post-RTO recovery verified Thu Nov 19 18:49:29 WIB 2026
Failover=0; monitor stopped; routes restored 7/9; eth1 and phy0-sta0 both reached 1.1.1.1; Xray DNS resolved example.com; HTTP=204. Automatic RTO test must not be repeated before single-instance locking and DNS-independent probes are implemented.

### Before failover RTO fix v8 Thu Nov 19 19:01:30 WIB 2026
Previous RTO test failed safely because duplicate monitor instances appeared and DNS-dependent probes classified both WANs unhealthy. Recovery completed. Candidate v8 adds single-instance flock and per-interface DNS-independent probe_ip=1.1.1.1. Bundle SHA256=9875842be2f43690d6f500f16bf190e4429c58b24530573f6356698db9934a9a. Melolo adblock remains separate in /etc/config/dhcp.

### Failover RTO fix v8 committed Thu Nov 19 19:04:14 WIB 2026
commit_rc=0; 70 tests passed; single-instance flock added; probes use per-interface probe_ip=1.1.1.1 without router DNS; custom probe_ip preserved; runtime unchanged; failover remains disabled.

### Hotplug backup cleanup Thu Nov 19 19:26:06 WIB 2026
Moved two executable backup DHCP hotplug scripts out of /etc/hotplug.d/dhcp into /root/legacy-automation-archive/hotplug. Only guarded 95-netcontrol-once remains. Router stayed paused/Direct; routes remained metric 7/9.

### Runtime a32f4dd installed Thu Nov 19 22:31:33 WIB 2026
Core and routing APK reinstall passed. Backup=/root/pre-a32f4dd-20261119-223051.tar.gz SHA256=768c50558f5c824f1c94d8f22079548e965cb21194b2387beeb4ea052719dca5. Failover=0; probe_ip=1.1.1.1; monitor stopped; service disabled; routes 7/9; HTTP=204.

### Runtime single-instance v8 passed Thu Nov 19 22:32:24 WIB 2026
Installed monitor passed single-instance lock test; rc=0. Failover remained 0; no monitor process remained; routes stayed metric 7/9.

### Runtime probe_ip v8 passed Thu Nov 19 22:33:19 WIB 2026
Both WANs reached probe_ip 1.1.1.1 with 0% loss: eth1 avg 76ms; phy0-sta0 avg 15ms. Failover remains disabled; RTO retest not started.

### RTO v8 pretest ended safely Thu Nov 19 22:40:30 WIB 2026
Single-instance runtime confirmed count=1, but primary outage was not performed. Failover returned to 0; monitor stopped; routes 7/9; paused/Direct; both WAN probes had 0% loss. Automatic RTO remains unverified.

### RTO v8 test aborted safely Thu Nov 19 22:44:22 WIB 2026
Test stopped before primary outage because chat depended on primary internet. Single-instance count=1 was confirmed. Failover returned to 0; monitor stopped; rollback cancelled; routes restored 7/9; HTTP=204. Automatic RTO remains unverified.

### Synthetic automatic failover v8 passed Thu Nov 19 22:47:35 WIB 2026
Three synthetic primary probe failures triggered real route failover to phy0-sta0. Three recovery probes restored eth1. Final failover=0; monitor stopped; routes restored 7/9; HTTP=204. Physical WAN outage remains untested.

### Dual probe candidates passed Thu Nov 19 22:50:10 WIB 2026
Both eth1 and phy0-sta0 reached 1.1.1.1 and 8.8.8.8 with 0% loss. Failover remained 0; routes stayed 7/9. Permanent activation deferred until dual-probe logic is implemented.

### Before dual-probe v9 Thu Nov 19 22:59:52 WIB 2026
Candidate v9 uses 1.1.1.1 and 8.8.8.8; WAN is unhealthy only when both probes fail. Threshold remains 3/3. Bundle SHA256=a8c7436fe67a4d2873b0a3b260ec3cec07c0b8f41af15752fe55b6dbe48def3a. Runtime remains failover=0 and paused/Direct.

### Dual-probe v9 committed Thu Nov 19 23:02:18 WIB 2026
commit_rc=0; 71 tests passed; WAN health uses 1.1.1.1 and 8.8.8.8; WAN fails only when both probes fail; custom probe values preserved; runtime unchanged; failover remains disabled.

### Manual traffic policy runtime fixed Thu Nov 19 23:28:49 WIB 2026
Stale runtime mark 0x4a06 was replaced transactionally with 0x102. Rule 99 matched table 101. YouTube test raised manual_3 to 576 packets/146051 bytes, and QUIC traffic exited via phy0-sta0 with source 192.168.1.20. DNS and HTTP remained healthy.

### Integrated Direct routing v10 committed Thu Nov 19 23:59:43 WIB 2026
commit_rc=0; 73 tests passed. Active bonding remains unaffected. Paused Direct refreshes traffic policy; general traffic uses primary with secondary fallback; manual wwan traffic uses secondary with primary fallback and 3/3 recovery. Runtime unchanged; failover remains disabled.

### Runtime d406aac installed Fri Nov 20 11:36:01 WIB 2026
Routing APK reinstall passed. Backup=/root/pre-d406aac-20261120-113316.tar.gz SHA256=7442a198d30e5c84e228076708651237a3898a3586c5534ddc3791a2661dff67. Failover=0; monitor stopped; service disabled; manual mark=0x102; defaults 7/9; table101=phy0-sta0.

### Policy fallback v10 runtime bug Fri Nov 20 11:38:59 WIB 2026
Synthetic wwan failure moved table101 toward eth1, but helper retained the old default route. Table101 contained eth1 metric7 and phy0-sta0 metric9, so restore could not reprioritize wwan. Recovery flushed table101 and restored only phy0-sta0 metric9; rule99 remained 0x102/0x1ff; defaults remained 7/9. Do not enable failover pending transactional table replacement.

### Policy route transaction v11 committed Fri Nov 20 11:47:00 WIB 2026
commit_rc=0; 74 tests passed. Table101 update now uses lock, snapshot, flush, exactly one verified default route, and rollback on failure. Runtime remains failover=0; table101 remains phy0-sta0.

### Temporary primary failover to wwan Fri Nov 20 13:02:23 WIB 2026
eth1 showed 60-70% loss and 111-125ms latency. Default temporarily changed to phy0-sta0 metric5 with eth1 metric7. Xray DNS restarted and recovered; DNS normal; HTTP=204; total=0.106s. Failover service remains disabled pending c47f74c artifact.

### Runtime c47f74c installed Fri Nov 20 13:11:30 WIB 2026
Routing APK passed. Backup=/root/pre-c47f74c-20261120-131103.tar.gz SHA256=54fd05a2fc200e66ae1c43e90cc8827daee80143988e3ff968cc34a797b8f77f. Failover=0; monitor stopped; service disabled; default wwan5/eth1-7; table101 only phy0-sta0; HTTP=204 total=0.119s.

### Policy route v11 runtime failure recovered Fri Nov 20 13:14:43 WIB 2026
Runtime verification rejected a valid route format, returned rc=6, and table101 was later found empty. Manually restored table101 to phy0-sta0 metric9 and rule99 to mark 0x102/0x1ff. HTTP=204 total=0.102s. Do not run paused-policy-failover or enable failover pending v12.

### Policy route runtime v12 committed Fri Nov 20 13:24:31 WIB 2026
commit_rc=0; 74 tests passed. Route verification now parses tokens and tolerates trailing whitespace; rollback is verified; safe secondary route prevents empty table101. Runtime unchanged; failover remains disabled.

### Runtime a6751a0 installed Fri Nov 20 16:26:36 WIB 2026
Routing APK passed. Backup=/root/pre-a6751a0-20261120-162604.tar.gz SHA256=946863b34e897fd5eb12100a4fcb8f806ff06f913feded39a057135d41326d19. Failover=0; monitor stopped; service disabled; default wwan5/eth1-7; table101 only phy0-sta0 metric9.

### Runtime policy transaction a6751a0 passed Sat Nov 21 08:53:00 WIB 2026
Primary fallback succeeded with exactly one table101 route via eth1 metric7. Secondary restore succeeded with exactly one route via phy0-sta0 metric9. Rule99 remained 0x102/0x1ff; general defaults remained eth1-7/wwan-9.

### Synthetic policy threshold partial test Sat Nov 21 08:57:00 WIB 2026
Three synthetic wwan failures successfully triggered table101 fallback to eth1 with exactly one route. Recovery loop was not executed because shell variable M was empty. Manual helper restore succeeded; table101 returned to phy0-sta0 metric9; rule99 remained correct; defaults remained 7/9; failover=0 and monitor stopped.

### Runtime automatic policy failover a6751a0 passed Sat Nov 21 08:58:29 WIB 2026
Three synthetic wwan failures moved table101 to eth1 with exactly one route. Three recoveries restored table101 to phy0-sta0 with exactly one route. Rule99 remained 0x102/0x1ff; defaults stayed 7/9; final failover=0; monitor stopped; HTTP=204 total=0.330s.

### Permanent failover trial stopped safely Sat Nov 21 09:05:13 WIB 2026
One monitor remained stable and no false route switch occurred. Found policy SRC counter growing to 16 while PMODE=secondary. Failover returned to 0; service disabled; monitor stopped; defaults restored 7/9; table101 restored only to phy0-sta0 metric9. Permanent activation deferred pending counter-state hotfix.

### Policy counter v13 committed Sat Nov 21 09:31:47 WIB 2026
commit_rc=0; 75 tests passed. SRC and SFC now increment only while awaiting state transitions; stable policy states reset inactive counters to zero. Runtime unchanged; failover remains disabled.

### Runtime counter stability 7b80e02 passed Sat Nov 21 11:05:22 WIB 2026
One monitor remained stable for 120 seconds. Policy state stayed SFC=0 SRC=0 PMODE=secondary; no false switch; defaults stayed 7/9; table101 remained phy0-sta0. Failover returned to 0; monitor stopped; service remained disabled.

### Before reboot failover 7b80e02 Sat Nov 21 11:37:57 WIB 2026
Failover=1; service enabled; paused marker present; one stable monitor; defaults 7/9; table101=phy0-sta0.

### Permanent failover reboot test passed Sat Nov 21 11:48:42 WIB 2026
After reboot failover=1, service enabled, paused marker present, one monitor active, counters stable at zero, defaults 7/9, table101 on phy0-sta0. HTTPS passed on eth1 in 0.311s and wwan in 0.120s. ICMP to 8.8.8.8 via eth1 was blocked but 1.1.1.1 and HTTPS were healthy.

### Before HTTP-aware probe Sun Nov 22 21:55 WIB 2026
Controlled dual-ICMP failure triggered failover to phy0-sta0. After rules cleared, eth1 HTTPS returned 204 but both ICMP probes failed, preventing recovery. Root cause confirmed: monitor ignores configured check_url. Existing unrelated activate changes preserved in /root/pre-http-probe-20261122.patch. Runtime remains paused on phy0-sta0; do not Resume.

### HTTP-aware probe tests passed Sun Nov 22 22:07 WIB 2026
Root cause confirmed: eth1 HTTPS=204 while both ICMP probes failed, blocking recovery. Monitor now accepts HTTP 204 OR either ICMP probe. Independent HTTP/ICMP regressions passed. Effective full suite 75/75 passed; diff check clean. Monitor hash=75fe9767ac758404938d5f281cefe4daab4884126a32715b6fa8776a5de4af97. Runtime unchanged; still paused; do not Resume.
