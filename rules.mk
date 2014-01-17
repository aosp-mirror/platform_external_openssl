LOCAL_DIR := $(GET_LOCAL_DIR)

MODULE := $(LOCAL_DIR)
MODULE_USER := true

# get openssl_cflags
MODULE_SRCDEPS += $(LOCAL_DIR)/build-config-trusty.mk
include $(LOCAL_DIR)/build-config-trusty.mk

# get target_c_flags, target_c_includes, target_src_files
MODULE_SRCDEPS += $(LOCAL_DIR)/Crypto-trusty-config.mk
TARGET_ARCH := $(ARCH)
include $(LOCAL_DIR)/Crypto-trusty-config.mk

MODULE_SRCS += $(addprefix $(LOCAL_DIR)/,$(common_src_files) $(arm_src_files))

MODULE_CFLAGS += $(target_c_flags)
MODULE_CFLAGS += -Wno-error=implicit-function-declaration

# Global for other modules which include openssl headers
GLOBAL_CFLAGS += -DOPENSSL_SYS_TRUSTY

target_c_includes := $(patsubst external/openssl/%,%,$(target_c_includes))
GLOBAL_INCLUDES += $(addprefix $(LOCAL_DIR)/,$(target_c_includes))

MODULE_DEPS := \
	lib/openssl-stubs \
	lib/libc-trusty

include make/module.mk
