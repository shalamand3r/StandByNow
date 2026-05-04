#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <substrate.h>

static NSString *const kPrefsSuite = @"com.shalamand3r.standbynow";
static CFStringRef const kPrefsNotify = CFSTR("com.shalamand3r.standbynow/ReloadPrefs");

static NSUserDefaults *gPrefs = nil;

static BOOL gEnabled = YES;
static NSString *gActivation = @"tripleLock";

static BOOL gUseVolume = NO;
static BOOL gUseDoubleLock = NO;
static BOOL gUseTripleLock = YES;
static BOOL gUseHoldLock = NO;
static BOOL gUseDoubleHome = NO;
static BOOL gUseTripleHome = NO;
static BOOL gUseHoldHome = NO;

static NSTimeInterval gLastVolumeUpPressTime = 0;
static NSTimeInterval gLastVolumeDownPressTime = 0;

static void ToggleStandBy(void) {
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (![scene isKindOfClass:NSClassFromString(@"SBWindowScene")]) continue;

		UIWindowScene *windowScene = (UIWindowScene *)scene;

		id controller =
			((id (*)(id, SEL))objc_msgSend)(
				windowScene,
				NSSelectorFromString(@"ambientPresentationController")
			);

		if (!controller) continue;

		BOOL isPresented =
			((BOOL (*)(id, SEL))objc_msgSend)(
				controller,
				NSSelectorFromString(@"isPresented")
			);

		((void (*)(id, SEL, BOOL))objc_msgSend)(
			controller,
			NSSelectorFromString(@"_setPresented:"),
			!isPresented
		);
	}
}

static void InitPrefs(void) {
	if (gPrefs) return;

	NSDictionary *defaults = @{
		@"kEnabled": @YES,
		@"kActivation": @"tripleLock",
	};

	gPrefs = [[NSUserDefaults alloc] initWithSuiteName:kPrefsSuite];
	[gPrefs registerDefaults:defaults];
}

static void UpdatePrefs(void) {
	InitPrefs();

	[gPrefs synchronize];
	gEnabled = [gPrefs boolForKey:@"kEnabled"];
	gActivation = [gPrefs stringForKey:@"kActivation"] ?: @"tripleLock";

	gUseVolume = [gActivation isEqualToString:@"volume"];
	gUseDoubleLock = [gActivation isEqualToString:@"doubleLock"];
	gUseTripleLock = [gActivation isEqualToString:@"tripleLock"];
	gUseHoldLock = [gActivation isEqualToString:@"holdLock"];
	gUseDoubleHome = [gActivation isEqualToString:@"doubleHome"];
	gUseTripleHome = [gActivation isEqualToString:@"tripleHome"];
	gUseHoldHome = [gActivation isEqualToString:@"holdHome"];
}

static void PrefsChangeCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
	UpdatePrefs();
}

static void DetectBothVolumeButtonsPressed(void) {
	if (!gEnabled || !gUseVolume) return;
	if (fabs(gLastVolumeUpPressTime - gLastVolumeDownPressTime) < 0.1) {
		ToggleStandBy();
	}
}

static void (*orig_performTriplePressActions)(id, SEL);
static void (*orig_performDoublePressActions)(id, SEL);
static void (*orig_performLongPressActions_lock)(id, SEL);
static BOOL (*orig_shouldWaitForDoublePress)(id, SEL);

static void (*orig_volumeIncreasePressDown)(id, SEL);
static void (*orig_volumeDecreasePressDown)(id, SEL);
static void (*orig_volumeIncreasePressDownWithModifiers)(id, SEL, long long);
static void (*orig_volumeDecreasePressDownWithModifiers)(id, SEL, long long);

static void (*orig_performLongPressActions_home)(id, SEL);
static void (*orig_performDoublePressDownActions_home)(id, SEL);
static void (*orig_performTriplePressUpActions_home)(id, SEL);

static void custom_performTriplePressActions(id self, SEL _cmd) {
	if (gEnabled && gUseTripleLock) {
		ToggleStandBy();
		return;
	}
	if (orig_performTriplePressActions) orig_performTriplePressActions(self, _cmd);
}

static void custom_performDoublePressActions(id self, SEL _cmd) {
	if (gEnabled && gUseDoubleLock) {
		ToggleStandBy();
		return;
	}
	if (orig_performDoublePressActions) orig_performDoublePressActions(self, _cmd);
}

static void custom_performLongPressActions_lock(id self, SEL _cmd) {
	if (gEnabled && gUseHoldLock) {
		ToggleStandBy();
		return;
	}
	if (orig_performLongPressActions_lock) orig_performLongPressActions_lock(self, _cmd);
}

static BOOL custom_shouldWaitForDoublePress(id self, SEL _cmd) {
	if (gEnabled && gUseDoubleLock) {
		return YES;
	}
	return orig_shouldWaitForDoublePress ? orig_shouldWaitForDoublePress(self, _cmd) : NO;
}

static void custom_volumeIncreasePressDown(id self, SEL _cmd) {
	if (gEnabled && gUseVolume) {
		gLastVolumeUpPressTime = [NSDate timeIntervalSinceReferenceDate];
		DetectBothVolumeButtonsPressed();
	}
	if (orig_volumeIncreasePressDown) orig_volumeIncreasePressDown(self, _cmd);
}

static void custom_volumeDecreasePressDown(id self, SEL _cmd) {
	if (gEnabled && gUseVolume) {
		gLastVolumeDownPressTime = [NSDate timeIntervalSinceReferenceDate];
		DetectBothVolumeButtonsPressed();
	}
	if (orig_volumeDecreasePressDown) orig_volumeDecreasePressDown(self, _cmd);
}

static void custom_volumeIncreasePressDownWithModifiers(id self, SEL _cmd, long long arg1) {
	if (gEnabled && gUseVolume) {
		gLastVolumeUpPressTime = [NSDate timeIntervalSinceReferenceDate];
		DetectBothVolumeButtonsPressed();
	}
	if (orig_volumeIncreasePressDownWithModifiers) orig_volumeIncreasePressDownWithModifiers(self, _cmd, arg1);
}

static void custom_volumeDecreasePressDownWithModifiers(id self, SEL _cmd, long long arg1) {
	if (gEnabled && gUseVolume) {
		gLastVolumeDownPressTime = [NSDate timeIntervalSinceReferenceDate];
		DetectBothVolumeButtonsPressed();
	}
	if (orig_volumeDecreasePressDownWithModifiers) orig_volumeDecreasePressDownWithModifiers(self, _cmd, arg1);
}

static void custom_performLongPressActions_home(id self, SEL _cmd) {
	if (gEnabled && gUseHoldHome) {
		ToggleStandBy();
		return;
	}
	if (orig_performLongPressActions_home) orig_performLongPressActions_home(self, _cmd);
}

static void custom_performDoublePressDownActions_home(id self, SEL _cmd) {
	if (gEnabled && gUseDoubleHome) {
		ToggleStandBy();
		return;
	}
	if (orig_performDoublePressDownActions_home) orig_performDoublePressDownActions_home(self, _cmd);
}

static void custom_performTriplePressUpActions_home(id self, SEL _cmd) {
	if (gEnabled && gUseTripleHome) {
		ToggleStandBy();
		return;
	}
	if (orig_performTriplePressUpActions_home) orig_performTriplePressUpActions_home(self, _cmd);
}

__attribute__((constructor)) static void init() {
	@autoreleasepool {
		UpdatePrefs();
		CFNotificationCenterAddObserver(
			CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			PrefsChangeCallback,
			kPrefsNotify,
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately
		);

		Class lockCls = NSClassFromString(@"SBLockHardwareButtonActions");
		if (lockCls) {
			MSHookMessageEx(lockCls, @selector(performTriplePressActions), (IMP)&custom_performTriplePressActions, (IMP *)&orig_performTriplePressActions);
			MSHookMessageEx(lockCls, @selector(performDoublePressActions), (IMP)&custom_performDoublePressActions, (IMP *)&orig_performDoublePressActions);
			MSHookMessageEx(lockCls, @selector(performLongPressActions), (IMP)&custom_performLongPressActions_lock, (IMP *)&orig_performLongPressActions_lock);
			MSHookMessageEx(lockCls, @selector(_shouldWaitForDoublePress), (IMP)&custom_shouldWaitForDoublePress, (IMP *)&orig_shouldWaitForDoublePress);
		}

		Class volCls = NSClassFromString(@"SBVolumeHardwareButtonActions");
		if (volCls) {
			MSHookMessageEx(volCls, @selector(volumeIncreasePressDown), (IMP)&custom_volumeIncreasePressDown, (IMP *)&orig_volumeIncreasePressDown);
			MSHookMessageEx(volCls, @selector(volumeDecreasePressDown), (IMP)&custom_volumeDecreasePressDown, (IMP *)&orig_volumeDecreasePressDown);
			MSHookMessageEx(volCls, @selector(volumeIncreasePressDownWithModifiers:), (IMP)&custom_volumeIncreasePressDownWithModifiers, (IMP *)&orig_volumeIncreasePressDownWithModifiers);
			MSHookMessageEx(volCls, @selector(volumeDecreasePressDownWithModifiers:), (IMP)&custom_volumeDecreasePressDownWithModifiers, (IMP *)&orig_volumeDecreasePressDownWithModifiers);
		}

		Class homeCls = NSClassFromString(@"SBHomeHardwareButtonActions");
		if (homeCls) {
			MSHookMessageEx(homeCls, @selector(performLongPressActions), (IMP)&custom_performLongPressActions_home, (IMP *)&orig_performLongPressActions_home);
			MSHookMessageEx(homeCls, @selector(performDoublePressDownActions), (IMP)&custom_performDoublePressDownActions_home, (IMP *)&orig_performDoublePressDownActions_home);
			MSHookMessageEx(homeCls, @selector(performTriplePressUpActions), (IMP)&custom_performTriplePressUpActions_home, (IMP *)&orig_performTriplePressUpActions_home);
		}
	}
}
