include $(TOPDIR)/rules.mk
PKG_NAME:=mptcp-suite-dual-xray
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKGARCH:=all
include $(INCLUDE_DIR)/package.mk

define Package/mptcp-suite-dual-xray
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Optional dual-Xray compatibility for MPTCP Suite
  DEPENDS:=+luci-app-mptcp-suite +xray-core +jq +curl
endef

define Package/mptcp-suite-dual-xray/conffiles
/etc/xray-dns/config.json
endef

define Build/Compile
endef

define Package/mptcp-suite-dual-xray/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,mptcp-suite-dual-xray))
