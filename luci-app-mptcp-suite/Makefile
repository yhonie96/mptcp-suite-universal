include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mptcp-suite
PKG_VERSION:=0.1
PKG_RELEASE:=2
PKGARCH:=all

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-mptcp-suite
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=MPTCP Suite
  DEPENDS:=+mptcp-suite-core +mptcp-suite-routing +mptcp-suite-traffic +xray-core +jq +curl +rpcd +luci-base +ucode +uci +ip-full +nftables-json +jsonfilter
endef

define Package/luci-app-mptcp-suite/conffiles
/etc/config/mptcp_profiles
endef

define Build/Compile
endef

define Package/luci-app-mptcp-suite/install
	$(CP) ./files/* $(1)/
	chmod 600 $(1)/etc/config/mptcp_profiles
endef

$(eval $(call BuildPackage,luci-app-mptcp-suite))
