include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp-suite-routing
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/mptcp-suite-routing
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Universal MPTCP Suite routing planner
  DEPENDS:=+mptcp-suite-core +ip-full +jsonfilter +curl +flock
endef

define Build/Compile
endef

define Package/mptcp-suite-routing/install
	$(INSTALL_DIR) $(1)/usr/libexec/mptcp-suite
	$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/* $(1)/usr/libexec/mptcp-suite/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/mptcp-paused-failover $(1)/etc/init.d/mptcp-paused-failover
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/98-mptcp-paused-failover $(1)/etc/uci-defaults/98-mptcp-paused-failover
endef

$(eval $(call BuildPackage,mptcp-suite-routing))
