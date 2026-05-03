#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <substrate.h>

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

static void (*orig_performTriplePressActions)(id, SEL);

static void custom_performTriplePressActions(id self, SEL _cmd) {
	ToggleStandBy();
}

__attribute__((constructor)) static void init() {
	@autoreleasepool {
		Class cls = NSClassFromString(@"SBLockHardwareButtonActions");
		if (!cls) return;

		MSHookMessageEx(
			cls,
			@selector(performTriplePressActions),
			(IMP)&custom_performTriplePressActions,
			(IMP *)&orig_performTriplePressActions
		);
	}
}
