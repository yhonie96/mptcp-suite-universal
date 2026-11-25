# MPTCP Suite Universal

Modular OpenWrt LuCI and backend tooling for managing MultiPath TCP (MPTCP) bonding, paused/Direct fallback mode with traffic policy and failover monitoring, and Xray profile workflows.

## Packages

- `mptcp-suite-core`: Core MPTCP state, endpoint daemon, client limit sync, activation/rollback helpers, and boot/restore scripts.
- `mptcp-suite-traffic`: Traffic policy rules, routing helpers, and paused-mode failover monitoring.
- `mptcp-suite-dual-xray`: Xray profile management, limited profile controls, and traffic rule RPC handlers.
- `luci-app-mptcp-suite`: LuCI views (`mptcp`, `mptcp-setup`, `mptcp-source-editor`, `mptcp-backup`, `xray-profiles`) and RPCD/ACL definitions.

## Language & Contract Standards

- **LuCI User Interface**: Neutral Indonesian labels (including standard spelling such as `Draf`).
- **Code, RPC & Documentation**: US English for source identifiers, RPC object/method names, JSON keys, tests, and technical documentation.

## Running Tests

Run the shell test suite from the repository root:

    for t in tests/test-*.sh; do
      sh "$t" || exit 1
    done
