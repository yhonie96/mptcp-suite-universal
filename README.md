# MPTCP Suite Universal

Modular OpenWrt LuCI and backend tooling for managing MultiPath TCP (MPTCP) multi-WAN bonding, safe-by-default Paused/Direct fallback routing with failover monitoring, per-client traffic policies, and dual-profile Xray transparent proxy workflows.

## Architecture Overview

MPTCP Suite separates control-plane state, routing transactions, client traffic classification, and proxy profiles across five independent OpenWrt packages with zero device-specific interface or credential hardcoding:

- **Paused / Direct Mode (Safe Default):** Installed with `/etc/mptcp-suite/paused` present and `mptcp_suite.routing.applied='0'`. Client policy marks (`0x102`) route through table `101` while `mptcp-paused-failover` monitors primary and secondary WAN gateways and refreshes DNS on failover.
- **Active MPTCP Mode (Bonding):** Dynamically allocates routing tables (`11001`-`11003`), fwmarks, rule priorities (`104`-`106`), and TPROXY ports (`12000`-`12002`), configures `ip mptcp` endpoints, validates the `mptcp_tproxy` nftables table, and routes clients across `main` and `limited` Xray profiles.

## Packages

- `mptcp-suite-core`: Core UCI state (`/etc/config/mptcp_suite`), dynamic WAN/gateway detection, and resource allocator (`allocate`, `allocate-apply`, `detect`, `main-gateway`, `apply-limits`).
- `mptcp-suite-routing`: Transactional routing and failover execution (`routing-*`, `failover-*`) plus paused-mode health monitor (`mptcp-paused-failover`).
- `mptcp-suite-traffic`: Per-client traffic policy engine (`traffic-policy-*`), nftables mark generation, and LuCI policy management view.
- `mptcp-suite-dual-xray`: Secondary bandwidth-limited Xray service (`xray-5mbps`), DNS adblock/fallback service (`xray-dns`), geodata updater, and RPC handlers.
- `luci-app-mptcp-suite`: Tunnel lifecycle commands (`mptcp-activate`, `mptcp-direct-restore`, `mptcp-boot-restore`), endpoint daemon, Xray profile builder/runtime, backup/restore RPCs, and LuCI web interface.

## Prerequisites

- **Router OS:** OpenWrt `25.12.x` using `apk` package manager and `nftables`.
- **Kernel Support:** Linux kernel built with `CONFIG_MPTCP=y` and `mptcpize` / `ip mptcp` netlink support for multi-WAN subflow bonding.
- **Remote Server (for Active MPTCP Bonding):** True bandwidth aggregation requires an MPTCP-enabled remote VPS/server running an Xray VLESS/Reality inbound endpoint. Without a remote MPTCP server, the suite can still operate in Paused/Direct mode for multi-WAN failover and policy routing.

## Installation on OpenWrt 25.12.x

Download the `mptcp-suite-apks-x86_64` artifact (containing the five `action/*.apk` packages) from GitHub Actions, transfer them to `/tmp/mptcp-apk/` on your router, and install:

    apk add --allow-untrusted /tmp/mptcp-apk/*.apk
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/*
    /etc/init.d/rpcd reload
    /etc/init.d/uhttpd reload

Existing local UCI files (`/etc/config/mptcp_suite`, `/etc/config/traffic_policy`, `/etc/config/mptcp_profiles`) and `/etc/xray-dns/config.json` are preserved during upgrades; package defaults are saved alongside as `*.apk-new`.

## First-Time Setup Workflow

1. Open **LuCI -> MPTCP Suite** and run WAN/gateway detection to bind `primary_wan` and `secondary_wan` in `/etc/config/mptcp_suite`.
2. Configure your primary (`main`) and optional secondary (`limited`) Xray server profiles in **Xray Profiles**.
3. Assign LAN client rules (`default`, `wan1`, or `wwan` policy targets) in **Traffic Policy**.
4. Verify Paused/Direct failover stability before enabling **Active MPTCP** bonding.

## Language & Contract Standards

- **LuCI User Interface:** Neutral Indonesian labels (including standard spelling such as `Draf`).
- **Code, RPC & Documentation:** US English for source identifiers, RPC object/method names, JSON keys, tests, and technical documentation.

## Running Tests

    PASS=0; FAIL=0
    for t in tests/test-*.sh; do
      sh "$t" >/dev/null 2>&1 && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAILED: $t"; }
    done
    echo "TEST_SUMMARY: pass=$PASS fail=$FAIL"
