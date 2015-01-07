LOCAL_PATH := $(call my-dir)


## libcrypto

# Target static library
include $(CLEAR_VARS)
LOCAL_SDK_VERSION := 9
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libcrypto_static
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/crypto-sources.mk
include $(LOCAL_PATH)/crypto-sources.mk
include $(BUILD_STATIC_LIBRARY)

# Target shared library
include $(CLEAR_VARS)
LOCAL_SDK_VERSION := 9
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libcrypto
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/crypto-sources.mk
LOCAL_CFLAGS += -fvisibility=hidden -DBORINGSSL_SHARED_LIBRARY -DBORINGSSL_IMPLEMENTATION
include $(LOCAL_PATH)/crypto-sources.mk
include $(BUILD_SHARED_LIBRARY)

# Host static library
include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libcrypto_static
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/crypto-sources.mk
include $(LOCAL_PATH)/crypto-sources.mk
include $(BUILD_HOST_STATIC_LIBRARY)

# Host shared library
include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libcrypto-host
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_MULTILIB := both
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/crypto-sources.mk
LOCAL_CFLAGS += -fvisibility=hidden -DBORINGSSL_SHARED_LIBRARY -DBORINGSSL_IMPLEMENTATION
include $(LOCAL_PATH)/crypto-sources.mk
include $(BUILD_HOST_SHARED_LIBRARY)


## libssl

# Target static library
include $(CLEAR_VARS)
LOCAL_SDK_VERSION := 9
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libssl_static
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/ssl-sources.mk
include $(LOCAL_PATH)/ssl-sources.mk
include $(BUILD_STATIC_LIBRARY)

# Target shared library
include $(CLEAR_VARS)
LOCAL_SDK_VERSION := 9
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libssl
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/ssl-sources.mk
LOCAL_CFLAGS += -fvisibility=hidden -DBORINGSSL_SHARED_LIBRARY -DBORINGSSL_IMPLEMENTATION
LOCAL_SHARED_LIBRARIES=libcrypto
include $(LOCAL_PATH)/ssl-sources.mk
include $(BUILD_SHARED_LIBRARY)

# Host static library
include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libssl_static
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/ssl-sources.mk
include $(LOCAL_PATH)/ssl-sources.mk
include $(BUILD_HOST_STATIC_LIBRARY)

# Host shared library
include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE := libssl-host
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/include
LOCAL_MULTILIB := both
LOCAL_ADDITIONAL_DEPENDENCIES := $(LOCAL_PATH)/Android.mk $(LOCAL_PATH)/ssl-sources.mk
LOCAL_CFLAGS += -fvisibility=hidden -DBORINGSSL_SHARED_LIBRARY -DBORINGSSL_IMPLEMENTATION
LOCAL_SHARED_LIBRARIES += libcrypto-host
include $(LOCAL_PATH)/ssl-sources.mk
include $(BUILD_HOST_SHARED_LIBRARY)
