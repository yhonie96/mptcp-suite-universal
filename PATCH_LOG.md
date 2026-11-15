# MPTCP Suite Patch Log

Riwayat sejak 0145995, urutan lama ke baru.

- `79260f9` fix: keep MPTCP RPC responses JSON-only
- `4261720` fix: add IPv4 fallback for apk index updates
- `0ca1155` feat: add configurable WAN failover planner
- `d25fc8e` fix: package all MPTCP routing helpers
- `100f94f` test: add dry-run WAN failover route actions
- `e39ff44` fix: make WAN failover route actions specific
- `475f07a` fix: declare routing failover dependencies
- `ebd8cf3` fix: validate WAN failover route parameters
- `c16d86e` feat: add safe WAN failover executor entrypoint
- `d952d47` feat: lock and snapshot WAN failover execution
- `a017b6b` fix: validate WAN failover route inputs
- `76f7922` feat: add guarded transactional WAN failover
- `9a0f520` test: verify WAN failover transaction rollback
- `51bc17e` fix: execute WAN failover routes without shell strings
- `46a5db2` feat: add validated WAN route snapshot restore
- `6b98119` routing: restore route snapshot after failed failover validation
- `9abdb47` test: cover failover rollback and snapshot restore failures
- `c5833f7` routing: preserve main table during failover
- `fc7c0d0` routing: validate failover policy route before success
- `f2d9ea3` core: remove router-specific default WAN
- `97fb091` core: remove default secondary WAN
- `57400e0` core: parse main default gateway safely
- `7b8b3ec` core: detect main WAN gateways safely
- `0774477` ci: update core file count
- `f0a5194` ci: fix static validation count
- `3049af3` luci: keep endpoint repair paused-safe
- `99d0fad` luci: fail boot reconnect safely
- `ee8ba32` core: manage MPTCP limits at boot
- `3ac269d` test: cover MPTCP limits helper
- `ca6f8f8` ci: expose SDK build failure output
- `007d255` ci: print SDK failure directly
- `966f196` ci: upload SDK logs on failure
- `ea04875` fix: use tabs in core install recipe
- `3e5d6ff` fix: normalize all core install recipe tabs
- `0b9ea66` test: expect six core install recipe tabs
- `d7cfeb2` fix: preserve traffic policy and restore MPTCP rollback
- `0a742a4` fix: retry Direct connectivity after Xray restart
- `22afa3e` fix: jangan batalkan Jeda saat cek internet Direct gagal
- `edb13a6` fix: mptcp-reconnect menolak berjalan saat MPTCP dijeda
- `240fd64` fix: perbaiki guard jeda bsbf-endpoint-repair (&& ter-escape)
- `4028072` fix: konversi Direct pilih outbound polos tanpa redirect VPS
- `ad3b3c7` test: sesuaikan ekspektasi rpcd dengan perilaku jeda baru
- `8819ca3` test: wajibkan guard jeda di mptcp-reconnect
- `dbaf2bc` test: larang guard jeda ter-escape di bsbf-endpoint-repair
- `c7567bf` chore: bump luci-app-mptcp-suite PKG_RELEASE ke 2
- `80ad9c0` fix: decode accidentally encoded package sources
- `a73b4ac` fix: disable unsafe diversion while paused
- `a8cd977` fix: let UCI own the TPROXY policy rule

## Catatan penting
- 22afa3e sampai c7567bf sempat menyimpan 8 file sebagai Base64.
- 80ad9c0 memulihkan seluruh file tersebut.
- a73b4ac mengamankan mode paused dan memblokir Resume.
- a8cd977 menjadikan UCI pemilik policy rule TPROXY.

## Status
- Tes lokal: FINAL_RC=0.
- Router: paused; WAN1=7; wwan=9; HTTP=204.
- TPROXY universal dan audit artifact belum selesai.
- WORKTREE: mptcp-activate memuat dan memvalidasi tabel diversion saat Resume; rollback kembali ke paused/Direct.
- Tes diversion check/load/table/set dan rollback seluruhnya lulus.
- Audit akhir: paused=0, dependency=0, table_present=1, FINAL_RC=0.
- Audit runtime: dua kali kehilangan internet dipulihkan dengan menghapus bsbf_bonding dan direct-restore; HTTP kembali 204.
- Kondisi aman akhir: marker paused ada, tabel bsbf_bonding tidak ada, netcontrol dan bsbf-bonding-nft boot disabled.
