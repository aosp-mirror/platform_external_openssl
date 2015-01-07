LOCAL_ADDITIONAL_DEPENDENCIES += $(LOCAL_PATH)/sources.mk
include $(LOCAL_PATH)/sources.mk

LOCAL_CFLAGS += -I$(LOCAL_PATH)/src/include -Wno-unused-parameter
LOCAL_EXPORT_C_INCLUDES += external/openssl/src/include
LOCAL_SRC_FILES += $(ssl_sources)
