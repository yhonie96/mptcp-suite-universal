include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp-suite-core
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/mptcp-suite-core
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Universal MPTCP Suite core
  DEPENDS:=+ip-full +nftables +jsonfilter
endef

define Package/mptcp-suite-core/conffiles
/etc/config/mptcp_suite
endef

define Build/Compile
endef

define Package/mptcp-suite-core/install
$(INSTALL_DIR) $(1)/etc/init.d
$(INSTALL_BIN) ./files/etc/init.d/mptcp-suite-core $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/mptcp_suite $(1)/etc/config/mptcp_suite
	$(INSTALL_DIR) $(1)/usr/libexec/mptcp-suite
	$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/* $(1)/usr/libexec/mptcp-suite/
endef

$(eval $(call BuildPackage,mptcp-suite-core))
