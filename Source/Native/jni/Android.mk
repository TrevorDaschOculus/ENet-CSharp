LOCAL_PATH := $(call my-dir)


include $(CLEAR_VARS)
LOCAL_MODULE    := ssl
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/prebuilt/openssl/$(TARGET_ARCH_ABI)/include
LOCAL_SRC_FILES := prebuilt/openssl/$(TARGET_ARCH_ABI)/lib/libssl.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE    := crypto
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/prebuilt/openssl/$(TARGET_ARCH_ABI)/include
LOCAL_SRC_FILES := prebuilt/openssl/$(TARGET_ARCH_ABI)/lib/libcrypto.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE    := libenet
LOCAL_SRC_FILES := ../enet.c
LOCAL_LDLIBS := -llog

ifdef ENET_DEBUG
	LOCAL_CFLAGS += -DENET_DEBUG
endif

ifdef ENET_STATIC
LOCAL_SHARED_LIBRARIES := ssl crypto
	include $(BUILD_STATIC_LIBRARY)
else
LOCAL_STATIC_LIBRARIES := ssl crypto
	include $(BUILD_SHARED_LIBRARY)
endif
