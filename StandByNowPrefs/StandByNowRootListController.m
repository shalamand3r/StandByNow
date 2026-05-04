#import <Foundation/Foundation.h>
#import "StandByNowRootListController.h"

#define BUNDLE @"com.shalamand3r.standbynow"
#define BUNDLE_NOTIFY (CFStringRef)@"com.shalamand3r.standbynow/ReloadPrefs"

@implementation StandByNowRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)loadView {
	[super loadView];
	((UITableView *)[self table]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	[self reloadSpecifiers];
}

- (void)Reset {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	NSArray *allKeys = [prefs dictionaryRepresentation].allKeys;
	for (NSString *key in allKeys) {
		[prefs removeObjectForKey:key];
	}
	[prefs synchronize];

	[self reloadSpecifiers];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), BUNDLE_NOTIFY, nil, nil, true);
}

@end
