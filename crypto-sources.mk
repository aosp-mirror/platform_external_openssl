LOCAL_ADDITIONAL_DEPENDENCIES += $(LOCAL_PATH)/sources.mk
include $(LOCAL_PATH)/sources.mk

LOCAL_CFLAGS += -I$(LOCAL_PATH)/src/include -I$(LOCAL_PATH)/src/crypto -Wno-unused-parameter
LOCAL_EXPORT_C_INCLUDES += external/openssl/src/include
LOCAL_SRC_FILES_x86 = $(linux_x86_sources)
LOCAL_SRC_FILES_x86_64 = $(linux_x86_64_sources)
LOCAL_SRC_FILES_arm = $(linux_arm_sources)
LOCAL_SRC_FILES += $(crypto_sources)
