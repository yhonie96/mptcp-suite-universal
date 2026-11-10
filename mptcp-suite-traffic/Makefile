include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp-suite-traffic
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/mptcp-suite-traffic
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Universal MPTCP Suite traffic policy planner
  DEPENDS:=+mptcp-suite-core +mptcp-suite-routing +nftables +uci
endef

define Build/Compile
endef

define Package/mptcp-suite-traffic/install
	$(INSTALL_DIR) $(1)/usr/libexec/mptcp-suite
	$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/traffic-plan $(1)/usr/libexec/mptcp-suite/
endef

$(eval $(call BuildPackage,mptcp-suite-traffic))
