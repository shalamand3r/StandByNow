TARGET := iphone:clang:latest
THEOS_PACKAGE_SCHEME = rootless

DEBUG = 0
PACKAGE_VERSION = 1.0
PACKAGE_REVISION = 1

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += modules/StandByNowSpringBoard

include $(THEOS_MAKE_PATH)/aggregate.mk
