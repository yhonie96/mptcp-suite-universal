include $(TOPDIR)/rules.mk

PKG_NAME:=mptcp-suite-traffic
PKG_VERSION:=0.2
PKG_RELEASE:=1
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/mptcp-suite-traffic
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Universal MPTCP Suite traffic policy
  DEPENDS:=+mptcp-suite-core +mptcp-suite-routing +nftables +uci +rpcd +luci-base +libubox
endef

define Build/Compile
endef

define Package/mptcp-suite-traffic/conffiles
/etc/config/traffic_policy
endef

define Package/mptcp-suite-traffic/install
	$(INSTALL_DIR) $(1)/usr/libexec/mptcp-suite
	$(INSTALL_BIN) ./files/usr/libexec/mptcp-suite/traffic-plan $(1)/usr/libexec/mptcp-suite/

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/traffic-policy-generate $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/usr/sbin/traffic-policy-apply $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/usr/sbin/traffic-policy-validate $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/traffic-policy $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/traffic_policy $(1)/etc/config/

	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./files/usr/libexec/rpcd/mptcp-suite-traffic $(1)/usr/libexec/rpcd/

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/status
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/status/traffic-policy-manual.js $(1)/www/luci-static/resources/view/status/

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/mptcp-suite-traffic.json $(1)/usr/share/luci/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/mptcp-suite-traffic.json $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,mptcp-suite-traffic))
