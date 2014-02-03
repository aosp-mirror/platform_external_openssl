#
# These flags represent the build-time configuration of OpenSSL for android
#
# The value of $(openssl_cflags) was pruned from the Makefile generated
# by running ./Configure from import_openssl.sh.
#
# This script performs minor but required patching for the Android build.
#

LOCAL_CFLAGS_32 += $(openssl_cflags_32)
LOCAL_CFLAGS_64 += $(openssl_cflags_64)

LOCAL_CFLAGS_32 := $(filter-out -DTERMIO, $(LOCAL_CFLAGS_32))
LOCAL_CFLAGS_64 := $(filter-out -DTERMIO, $(LOCAL_CFLAGS_64))

ifeq ($(HOST_OS),windows)
LOCAL_CFLAGS_32 := $(filter-out -DDSO_DLFCN -DHAVE_DLFCN_H,$(LOCAL_CFLAGS_32))
LOCAL_CFLAGS_64 := $(filter-out -DDSO_DLFCN -DHAVE_DLFCN_H,$(LOCAL_CFLAGS_64))
endif

# Intentionally excluded http://b/7079965
LOCAL_CFLAGS_32 := $(filter-out -DZLIB, $(LOCAL_CFLAGS_32))
LOCAL_CFLAGS_64 := $(filter-out -DZLIB, $(LOCAL_CFLAGS_64))

# Directories
LOCAL_CFLAGS += \
  -DOPENSSLDIR="\"/system/lib/ssl\"" \
  -DENGINESDIR="\"/system/lib/ssl/engines\""

LOCAL_CFLAGS += -Wno-missing-field-initializers -Wno-unused-parameter

# Debug
# LOCAL_CFLAGS += -DCIPHER_DEBUG

# Add clang here when it works on host
# LOCAL_CLANG := true
