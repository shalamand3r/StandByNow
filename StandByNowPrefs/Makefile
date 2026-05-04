TARGET := iphone:clang:latest
THEOS_PACKAGE_SCHEME = rootless
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = StandByNowPrefs

StandByNowPrefs_FILES = StandByNowRootListController.m
StandByNowPrefs_FRAMEWORKS = UIKit
StandByNowPrefs_PRIVATE_FRAMEWORKS = Preferences
StandByNowPrefs_INSTALL_PATH = /Library/PreferenceBundles
StandByNowPrefs_CFLAGS = -fobjc-arc -fmodules-cache-path=$(THEOS_PROJECT_DIR)/.theos/ModuleCache

include $(THEOS_MAKE_PATH)/bundle.mk

after-stage::
	@/usr/local/bin/ldid -S "$(THEOS_STAGING_DIR)/var/jb/Library/PreferenceBundles/StandByNowPrefs.bundle/StandByNowPrefs" || true
