# Auto-generated - DO NOT EDIT!
# To regenerate, edit openssl.config, then run:
#     ./import_openssl.sh import /path/to/openssl-1.0.1f.tar.gz
#
# This script will append to the following variables:
#
#    LOCAL_CFLAGS
#    LOCAL_C_INCLUDES
#    LOCAL_SRC_FILES_$(TARGET_ARCH)
#    LOCAL_SRC_FILES_$(TARGET_2ND_ARCH)
#    LOCAL_CFLAGS_$(TARGET_ARCH)
#    LOCAL_CFLAGS_$(TARGET_2ND_ARCH)
#    LOCAL_ADDITIONAL_DEPENDENCIES


LOCAL_ADDITIONAL_DEPENDENCIES += $(LOCAL_PATH)/Apps-config-host.mk

common_cflags := \
  -DMONOLITH \

local_cflags :=

common_src_files := \
  apps/app_rand.c \
  apps/apps.c \
  apps/asn1pars.c \
  apps/ca.c \
  apps/ciphers.c \
  apps/cms.c \
  apps/crl.c \
  apps/crl2p7.c \
  apps/dgst.c \
  apps/dh.c \
  apps/dhparam.c \
  apps/dsa.c \
  apps/dsaparam.c \
  apps/ec.c \
  apps/ecparam.c \
  apps/enc.c \
  apps/engine.c \
  apps/errstr.c \
  apps/gendh.c \
  apps/gendsa.c \
  apps/genpkey.c \
  apps/genrsa.c \
  apps/nseq.c \
  apps/ocsp.c \
  apps/openssl.c \
  apps/passwd.c \
  apps/pkcs12.c \
  apps/pkcs7.c \
  apps/pkcs8.c \
  apps/pkey.c \
  apps/pkeyparam.c \
  apps/pkeyutl.c \
  apps/prime.c \
  apps/rand.c \
  apps/req.c \
  apps/rsa.c \
  apps/rsautl.c \
  apps/s_cb.c \
  apps/s_client.c \
  apps/s_server.c \
  apps/s_socket.c \
  apps/s_time.c \
  apps/sess_id.c \
  apps/smime.c \
  apps/speed.c \
  apps/spkac.c \
  apps/srp.c \
  apps/verify.c \
  apps/version.c \
  apps/x509.c \

common_c_includes := \
  external/openssl/. \
  external/openssl/include \

arm_cflags :=

arm_src_files :=

arm_exclude_files :=

arm64_cflags :=

arm64_src_files :=

arm64_exclude_files :=

x86_cflags :=

x86_src_files :=

x86_exclude_files :=

x86_64_cflags :=

x86_64_src_files :=

x86_64_exclude_files :=

mips_cflags :=

mips_src_files :=

mips_exclude_files :=


ifeq ($(HOST_OS)-$(HOST_ARCH),linux-x86)
ifneq ($(BUILD_HOST_64bit),)
host_arch := x86_64
else
host_arch := x86
endif
else
ifeq ($(HOST_OS)-$(HOST_ARCH),linux-x86_64)
host_arch := x86_64
else
$(warning Unknown host architecture $(HOST_OS)-$(HOST_ARCH))
host_arch := unknown
endif
endif

LOCAL_CFLAGS     += $(common_cflags) $($(host_arch)_cflags) $(local_cflags)
LOCAL_C_INCLUDES += $(common_c_includes) $(local_c_includes)
LOCAL_SRC_FILES  += $(filter-out $($(host_arch)_exclude_files), $(common_src_files) $($(host_arch)_src_files))
