LOCAL_PATH := $(call my-dir)

HOSTAPD_ROOT = ..
TI_HOSTAPD_LIB = y

# define HOSTAPD_DUMP_STATE to include SIGUSR1 handler for dumping state to
# a file (undefine it, if you want to save in binary size)
L_CFLAGS += -DHOSTAPD_DUMP_STATE

INCLUDES = \
	$(LOCAL_PATH)/$(HOSTAPD_ROOT)/src \
	$(LOCAL_PATH)/$(HOSTAPD_ROOT)/src/crypto \
	$(LOCAL_PATH)/$(HOSTAPD_ROOT)/src/utils \
	$(LOCAL_PATH)/$(HOSTAPD_ROOT)/src/common \
	external/openssl/include

# Uncomment following line and set the path to your kernel tree include
# directory if your C library does not include all header files.
# L_CFLAGS += -DUSE_KERNEL_HEADERS +I/usr/src/linux/include

include $(LOCAL_PATH)/.config

ifndef CONFIG_OS
ifdef CONFIG_NATIVE_WINDOWS
CONFIG_OS=win32
else
CONFIG_OS=unix
endif
endif

ifeq ($(CONFIG_OS), internal)
L_CFLAGS += -DOS_NO_C_LIB_DEFINES
endif

ifdef CONFIG_NATIVE_WINDOWS
L_CFLAGS += -DCONFIG_NATIVE_WINDOWS
LIBS += -lws2_32
endif

OBJS =	hostapd.c ieee802_1x.c eapol_sm.c \
	ieee802_11.c config.c ieee802_11_auth.c accounting.c \
	sta_info.c wpa.c ctrl_iface.c \
	drivers.c preauth.c pmksa_cache.c beacon.c \
	hw_features.c wme.c ap_list.c \
	mlme.c vlan_init.c wpa_auth_ie.c

OBJS += ../src/utils/eloop.c
OBJS += ../src/utils/common.c
OBJS += ../src/utils/wpa_debug.c
OBJS += ../src/utils/wpabuf.c
OBJS += ../src/utils/os_$(CONFIG_OS).c
OBJS += ../src/utils/ip_addr.c

OBJS += ../src/common/ieee802_11_common.c
OBJS += ../src/common/wpa_common.c

OBJS += ../src/radius/radius.c
OBJS += ../src/radius/radius_client.c

OBJS += ../src/crypto/md5.c
OBJS += ../src/crypto/rc4.c
OBJS += ../src/crypto/md4.c
OBJS += ../src/crypto/sha1.c
OBJS += ../src/crypto/des.c
OBJS += ../src/crypto/aes_wrap.c
OBJS += ../src/crypto/aes.c


HOBJS=../src/hlr_auc_gw/hlr_auc_gw.c ../src/utils/common.c ../src/utils/wpa_debug.c ../src/utils/os_$(CONFIG_OS).c ../src/hlr_auc_gw/milenage.c ../src/crypto/aes_wrap.c ../src/crypto/aes.c

L_CFLAGS += -DCONFIG_CTRL_IFACE -DCONFIG_CTRL_IFACE_UNIX

ifdef CONFIG_IAPP
L_CFLAGS += -DCONFIG_IAPP
OBJS += iapp.c
endif

ifdef CONFIG_RSN_PREAUTH
L_CFLAGS += -DCONFIG_RSN_PREAUTH
CONFIG_L2_PACKET=y
endif

ifdef CONFIG_PEERKEY
L_CFLAGS += -DCONFIG_PEERKEY
OBJS += peerkey.c
endif

ifdef CONFIG_IEEE80211W
L_CFLAGS += -DCONFIG_IEEE80211W
NEED_SHA256=y
endif

ifdef CONFIG_IEEE80211R
L_CFLAGS += -DCONFIG_IEEE80211R
OBJS += wpa_ft.c
NEED_SHA256=y
endif

ifdef CONFIG_IEEE80211N
L_CFLAGS += -DCONFIG_IEEE80211N
endif

ifdef CONFIG_DRIVER_HOSTAP
L_CFLAGS += -DCONFIG_DRIVER_HOSTAP
OBJS += driver_hostap.c
endif

ifdef CONFIG_DRIVER_WILINK
L_CFLAGS += -DCONFIG_DRIVER_WILINK
INCLUDES += \
	system/wlan/ti/wilink_6_2/stad/Export_Inc \
	system/wlan/ti/wilink_6_2/utils \
	system/wlan/ti/wilink_6_2/platforms/os/linux/inc

CONFIG_L2_PACKET=linux
OBJS += regulatory.c
OBJS += driver_wilink.c 
endif

ifdef CONFIG_DRIVER_WIRED
L_CFLAGS += -DCONFIG_DRIVER_WIRED
OBJS += driver_wired.c
endif

ifdef CONFIG_DRIVER_MADWIFI
L_CFLAGS += -DCONFIG_DRIVER_MADWIFI
OBJS += driver_madwifi.c
CONFIG_L2_PACKET=y
endif

ifdef CONFIG_DRIVER_ATHEROS
L_CFLAGS += -DCONFIG_DRIVER_ATHEROS
OBJS += driver_atheros.c
CONFIG_L2_PACKET=y
endif

ifdef CONFIG_DRIVER_PRISM54
L_CFLAGS += -DCONFIG_DRIVER_PRISM54
OBJS += driver_prism54.c
endif

ifdef CONFIG_DRIVER_NL80211
L_CFLAGS += -DCONFIG_DRIVER_NL80211
OBJS += driver_nl80211.c radiotap.c
LIBS += -lnl
ifdef CONFIG_LIBNL20
LIBS += -lnl-genl
L_CFLAGS += -DCONFIG_LIBNL20
endif
endif

ifdef CONFIG_DRIVER_BSD
L_CFLAGS += -DCONFIG_DRIVER_BSD
OBJS += driver_bsd.c
CONFIG_L2_PACKET=y
CONFIG_DNET_PCAP=y
CONFIG_L2_FREEBSD=y
endif

ifdef CONFIG_DRIVER_TEST
L_CFLAGS += -DCONFIG_DRIVER_TEST
OBJS += driver_test.c
endif

ifdef CONFIG_DRIVER_NONE
L_CFLAGS += -DCONFIG_DRIVER_NONE
OBJS += driver_none.c
endif

ifdef CONFIG_L2_PACKET
ifdef CONFIG_DNET_PCAP
ifdef CONFIG_L2_FREEBSD
LIBS += -lpcap
OBJS += ../src/l2_packet/l2_packet_freebsd.c
else
LIBS += -ldnet -lpcap
OBJS += ../src/l2_packet/l2_packet_pcap.c
endif
else
OBJS += ../src/l2_packet/l2_packet_linux.c
endif
else
OBJS += ../src/l2_packet/l2_packet_none.c
endif


ifdef CONFIG_EAP_MD5
L_CFLAGS += -DEAP_MD5
OBJS += ../src/eap_server/eap_md5.c
CHAP=y
endif

ifdef CONFIG_EAP_TLS
L_CFLAGS += -DEAP_TLS
OBJS += ../src/eap_server/eap_tls.c
TLS_FUNCS=y
endif

ifdef CONFIG_EAP_PEAP
L_CFLAGS += -DEAP_PEAP
OBJS += ../src/eap_server/eap_peap.c
OBJS += ../src/eap_common/eap_peap_common.c
TLS_FUNCS=y
CONFIG_EAP_MSCHAPV2=y
endif

ifdef CONFIG_EAP_TTLS
L_CFLAGS += -DEAP_TTLS
OBJS += ../src/eap_server/eap_ttls.c
TLS_FUNCS=y
CHAP=y
endif

ifdef CONFIG_EAP_MSCHAPV2
L_CFLAGS += -DEAP_MSCHAPv2
OBJS += ../src/eap_server/eap_mschapv2.c
MS_FUNCS=y
endif

ifdef CONFIG_EAP_GTC
L_CFLAGS += -DEAP_GTC
OBJS += ../src/eap_server/eap_gtc.c
endif

ifdef CONFIG_EAP_SIM
L_CFLAGS += -DEAP_SIM
OBJS += ../src/eap_server/eap_sim.c
CONFIG_EAP_SIM_COMMON=y
endif

ifdef CONFIG_EAP_AKA
L_CFLAGS += -DEAP_AKA
OBJS += ../src/eap_server/eap_aka.c
CONFIG_EAP_SIM_COMMON=y
endif

ifdef CONFIG_EAP_AKA_PRIME
L_CFLAGS += -DEAP_AKA_PRIME
endif

ifdef CONFIG_EAP_SIM_COMMON
OBJS += ../src/eap_common/eap_sim_common.c
# Example EAP-SIM/AKA interface for GSM/UMTS authentication. This can be
# replaced with another file implementating the interface specified in
# eap_sim_db.h.
OBJS += ../src/eap_server/eap_sim_db.c
NEED_FIPS186_2_PRF=y
endif

ifdef CONFIG_EAP_PAX
L_CFLAGS += -DEAP_PAX
OBJS += ../src/eap_server/eap_pax.c ../src/eap_common/eap_pax_common.c
endif

ifdef CONFIG_EAP_PSK
L_CFLAGS += -DEAP_PSK
OBJS += ../src/eap_server/eap_psk.c ../src/eap_common/eap_psk_common.c
endif

ifdef CONFIG_EAP_SAKE
L_CFLAGS += -DEAP_SAKE
OBJS += ../src/eap_server/eap_sake.c ../src/eap_common/eap_sake_common.c
endif

ifdef CONFIG_EAP_GPSK
L_CFLAGS += -DEAP_GPSK
OBJS += ../src/eap_server/eap_gpsk.c ../src/eap_common/eap_gpsk_common.c
ifdef CONFIG_EAP_GPSK_SHA256
L_CFLAGS += -DEAP_GPSK_SHA256
endif
NEED_SHA256=y
endif

ifdef CONFIG_EAP_VENDOR_TEST
L_CFLAGS += -DEAP_VENDOR_TEST
OBJS += ../src/eap_server/eap_vendor_test.c
endif

ifdef CONFIG_EAP_FAST
L_CFLAGS += -DEAP_FAST
OBJS += ../src/eap_server/eap_fast.c
OBJS += ../src/eap_common/eap_fast_common.c
TLS_FUNCS=y
NEED_T_PRF=y
endif

ifdef CONFIG_WPS
L_CFLAGS += -DCONFIG_WPS -DEAP_WSC
OBJS += ../src/utils/uuid.c
OBJS += wps_hostapd.c
OBJS += ../src/eap_server/eap_wsc.c ../src/eap_common/eap_wsc_common.c
OBJS += ../src/wps/wps.c
OBJS += ../src/wps/wps_common.c
OBJS += ../src/wps/wps_attr_parse.c
OBJS += ../src/wps/wps_attr_build.c
OBJS += ../src/wps/wps_attr_process.c
OBJS += ../src/wps/wps_dev_attr.c
OBJS += ../src/wps/wps_enrollee.c
OBJS += ../src/wps/wps_registrar.c
NEED_DH_GROUPS=y
NEED_SHA256=y
NEED_CRYPTO=y
NEED_BASE64=y

ifdef CONFIG_WPS_UPNP
L_CFLAGS += -DCONFIG_WPS_UPNP
OBJS += ../src/wps/wps_upnp.c
OBJS += ../src/wps/wps_upnp_ssdp.c
OBJS += ../src/wps/wps_upnp_web.c
OBJS += ../src/wps/wps_upnp_event.c
OBJS += ../src/wps/httpread.c
endif

endif

ifdef CONFIG_EAP_IKEV2
L_CFLAGS += -DEAP_IKEV2
OBJS += ../src/eap_server/eap_ikev2.c ../src/eap_server/ikev2.c
OBJS += ../src/eap_common/eap_ikev2_common.c ../src/eap_common/ikev2_common.c
NEED_DH_GROUPS=y
endif

ifdef CONFIG_EAP_TNC
L_CFLAGS += -DEAP_TNC
OBJS += ../src/eap_server/eap_tnc.c
OBJS += ../src/eap_server/tncs.c
NEED_BASE64=y
ifndef CONFIG_DRIVER_BSD
LIBS += -ldl
endif
endif

# Basic EAP functionality is needed for EAPOL
OBJS += ../src/eap_server/eap.c
OBJS += ../src/eap_common/eap_common.c
OBJS += ../src/eap_server/eap_methods.c
OBJS += ../src/eap_server/eap_identity.c

ifdef CONFIG_EAP
L_CFLAGS += -DEAP_SERVER
endif

ifndef CONFIG_TLS
CONFIG_TLS=openssl
endif

ifeq ($(CONFIG_TLS), internal)
ifndef CONFIG_CRYPTO
CONFIG_CRYPTO=internal
endif
endif
ifeq ($(CONFIG_CRYPTO), libtomcrypt)
L_CFLAGS += -DCONFIG_INTERNAL_X509
endif
ifeq ($(CONFIG_CRYPTO), internal)
L_CFLAGS += -DCONFIG_INTERNAL_X509
endif


ifdef TLS_FUNCS
# Shared TLS functions (needed for EAP_TLS, EAP_PEAP, and EAP_TTLS)
L_CFLAGS += -DEAP_TLS_FUNCS
OBJS += ../src/eap_server/eap_tls_common.c
NEED_TLS_PRF=y
ifeq ($(CONFIG_TLS), openssl)
OBJS += ../src/crypto/tls_openssl.c
LIBS += -lssl -lcrypto
LIBS_p += -lcrypto
LIBS_h += -lcrypto
endif
ifeq ($(CONFIG_TLS), gnutls)
OBJS += ../src/crypto/tls_gnutls.c
LIBS += -lgnutls -lgcrypt -lgpg-error
LIBS_p += -lgcrypt
LIBS_h += -lgcrypt
endif
ifdef CONFIG_GNUTLS_EXTRA
L_CFLAGS += -DCONFIG_GNUTLS_EXTRA
LIBS += -lgnutls-extra
endif
ifeq ($(CONFIG_TLS), internal)
OBJS += ../src/crypto/tls_internal.c
OBJS += ../src/tls/tlsv1_common.c ../src/tls/tlsv1_record.c
OBJS += ../src/tls/tlsv1_cred.c ../src/tls/tlsv1_server.c
OBJS += ../src/tls/tlsv1_server_write.c ../src/tls/tlsv1_server_read.c
OBJS += ../src/tls/asn1.c ../src/tls/x509v3.c
OBJS_p += ../src/tls/asn1.c
OBJS_p += ../src/crypto/rc4.c ../src/crypto/aes_wrap.c ../src/crypto/aes.c
NEED_BASE64=y
L_CFLAGS += -DCONFIG_TLS_INTERNAL
L_CFLAGS += -DCONFIG_TLS_INTERNAL_SERVER
ifeq ($(CONFIG_CRYPTO), internal)
ifdef CONFIG_INTERNAL_LIBTOMMATH
L_CFLAGS += -DCONFIG_INTERNAL_LIBTOMMATH
else
LIBS += -ltommath
LIBS_p += -ltommath
endif
endif
ifeq ($(CONFIG_CRYPTO), libtomcrypt)
LIBS += -ltomcrypt -ltfm
LIBS_p += -ltomcrypt -ltfm
endif
endif
NEED_CRYPTO=y
else
OBJS += ../src/crypto/tls_none.c
endif

ifdef CONFIG_PKCS12
L_CFLAGS += -DPKCS12_FUNCS
endif

ifdef MS_FUNCS
OBJS += ../src/crypto/ms_funcs.c
NEED_CRYPTO=y
endif

ifdef CHAP
OBJS += ../src/eap_common/chap.c
endif

ifdef NEED_CRYPTO
ifndef TLS_FUNCS
ifeq ($(CONFIG_TLS), openssl)
LIBS += -lcrypto
LIBS_p += -lcrypto
LIBS_h += -lcrypto
endif
ifeq ($(CONFIG_TLS), gnutls)
LIBS += -lgcrypt
LIBS_p += -lgcrypt
LIBS_h += -lgcrypt
endif
ifeq ($(CONFIG_TLS), internal)
ifeq ($(CONFIG_CRYPTO), libtomcrypt)
LIBS += -ltomcrypt -ltfm
LIBS_p += -ltomcrypt -ltfm
endif
endif
endif
ifeq ($(CONFIG_TLS), openssl)
OBJS += ../src/crypto/crypto_openssl.c
OBJS_p += ../src/crypto/crypto_openssl.c
HOBJS += ../src/crypto/crypto_openssl.c
CONFIG_INTERNAL_SHA256=y
endif
ifeq ($(CONFIG_TLS), gnutls)
OBJS += ../src/crypto/crypto_gnutls.c
OBJS_p += ../src/crypto/crypto_gnutls.c
HOBJS += ../src/crypto/crypto_gnutls.c
CONFIG_INTERNAL_SHA256=y
endif
ifeq ($(CONFIG_TLS), internal)
ifeq ($(CONFIG_CRYPTO), libtomcrypt)
OBJS += ../src/crypto/crypto_libtomcrypt.c
OBJS_p += ../src/crypto/crypto_libtomcrypt.c
CONFIG_INTERNAL_SHA256=y
endif
ifeq ($(CONFIG_CRYPTO), internal)
OBJS += ../src/crypto/crypto_internal.c ../src/tls/rsa.c ../src/tls/bignum.c
OBJS_p += ../src/crypto/crypto_internal.c ../src/tls/rsa.c ../src/tls/bignum.c
L_CFLAGS += -DCONFIG_CRYPTO_INTERNAL
CONFIG_INTERNAL_AES=y
CONFIG_INTERNAL_DES=y
CONFIG_INTERNAL_SHA1=y
CONFIG_INTERNAL_MD4=y
CONFIG_INTERNAL_MD5=y
CONFIG_INTERNAL_SHA256=y
endif
endif
else
CONFIG_INTERNAL_AES=y
CONFIG_INTERNAL_SHA1=y
CONFIG_INTERNAL_MD5=y
CONFIG_INTERNAL_SHA256=y
endif

ifdef CONFIG_INTERNAL_AES
L_CFLAGS += -DINTERNAL_AES
endif
ifdef CONFIG_INTERNAL_SHA1
L_CFLAGS += -DINTERNAL_SHA1
endif
ifdef CONFIG_INTERNAL_SHA256
L_CFLAGS += -DINTERNAL_SHA256
endif
ifdef CONFIG_INTERNAL_MD5
L_CFLAGS += -DINTERNAL_MD5
endif
ifdef CONFIG_INTERNAL_MD4
L_CFLAGS += -DINTERNAL_MD4
endif
ifdef CONFIG_INTERNAL_DES
L_CFLAGS += -DINTERNAL_DES
endif

ifdef NEED_SHA256
OBJS += ../src/crypto/sha256.c
endif

ifdef NEED_DH_GROUPS
OBJS += ../src/crypto/dh_groups.c
endif

ifndef NEED_FIPS186_2_PRF
L_CFLAGS += -DCONFIG_NO_FIPS186_2_PRF
endif

ifndef NEED_T_PRF
L_CFLAGS += -DCONFIG_NO_T_PRF
endif

ifndef NEED_TLS_PRF
L_CFLAGS += -DCONFIG_NO_TLS_PRF
endif

ifdef CONFIG_RADIUS_SERVER
L_CFLAGS += -DRADIUS_SERVER
OBJS += ../src/radius/radius_server.c
endif

ifdef CONFIG_IPV6
L_CFLAGS += -DCONFIG_IPV6
endif

ifdef CONFIG_DRIVER_RADIUS_ACL
L_CFLAGS += -DCONFIG_DRIVER_RADIUS_ACL
endif

ifdef CONFIG_FULL_DYNAMIC_VLAN
# define CONFIG_FULL_DYNAMIC_VLAN to have hostapd manipulate bridges
# and vlan interfaces for the vlan feature.
L_CFLAGS += -DCONFIG_FULL_DYNAMIC_VLAN
endif

ifdef NEED_BASE64
OBJS += ../src/utils/base64.c
endif

ifdef CONFIG_NO_STDOUT_DEBUG
L_CFLAGS += -DCONFIG_NO_STDOUT_DEBUG
endif

ifdef CONFIG_NO_AES_EXTRAS
L_CFLAGS += -DCONFIG_NO_AES_UNWRAP
L_CFLAGS += -DCONFIG_NO_AES_CTR -DCONFIG_NO_AES_OMAC1
L_CFLAGS += -DCONFIG_NO_AES_EAX -DCONFIG_NO_AES_CBC
L_CFLAGS += -DCONFIG_NO_AES_DECRYPT
L_CFLAGS += -DCONFIG_NO_AES_ENCRYPT_BLOCK
endif

ifeq ($(TI_HOSTAPD_LIB), y)
L_CFLAGS += -DTI_HOSTAPD_CLI_LIB
endif

OBJS_c = \
	hostapd_cli.c \
	../src/common/wpa_ctrl.c \
	../src/utils/os_$(CONFIG_OS).c

########################
#
#include $(CLEAR_VARS)
#LOCAL_MODULE := hostapd
#LOCAL_MODULE_TAGS := debug
#LOCAL_SHARED_LIBRARIES := libc libcutils libcrypto libssl
#LOCAL_CFLAGS := $(L_CFLAGS)
#LOCAL_SRC_FILES := $(OBJS)
#LOCAL_C_INCLUDES := $(INCLUDES)
#include $(BUILD_EXECUTABLE)
#
########################

include $(CLEAR_VARS)
LOCAL_MODULE := libhostapdcli
LOCAL_MODULE_TAGS := debug
LOCAL_SHARED_LIBRARIES := libc libcutils
LOCAL_CFLAGS := $(L_CFLAGS)
LOCAL_SRC_FILES := $(OBJS_c)
LOCAL_C_INCLUDES := $(INCLUDES)
include $(BUILD_STATIC_LIBRARY)

########################
