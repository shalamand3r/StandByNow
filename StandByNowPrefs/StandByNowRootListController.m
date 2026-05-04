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
	
	UITableView *tableView = [self table];
	tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 180)];
	
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, 100, 100)];
	imageView.image = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"standbynow_header" ofType:@"png"]];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	imageView.center = CGPointMake(headerView.center.x, imageView.center.y);
	imageView.layer.cornerRadius = 22;
	imageView.layer.masksToBounds = YES;
	[headerView addSubview:imageView];
	
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 130, headerView.bounds.size.width, 40)];
	titleLabel.text = @"StandByNow";
	titleLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[headerView addSubview:titleLabel];
	
	tableView.tableHeaderView = headerView;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	if ([[specifier propertyForKey:@"key"] isEqualToString:@"kActivation"]) {
		[self updateFooterWithActivation:value];
	}
}

- (void)updateFooterWithActivation:(NSString *)activation {
	PSSpecifier *groupSpecifier = [self specifierForID:@"ConfigGroup"];
	if (!groupSpecifier) return;

	NSString *footerText = @"";
	if ([activation isEqualToString:@"tripleLock"]) {
		footerText = @"Overrides Accessibility Shortcuts.";
	} else if ([activation isEqualToString:@"doubleLock"]) {
		footerText = @"Overrides Apple Pay activation.";
	} else if ([activation isEqualToString:@"holdLock"]) {
		footerText = @"Overrides Siri.";
	} else if ([activation isEqualToString:@"volume"]) {
		footerText = @"Does not override system gestures.";
	} else if ([activation isEqualToString:@"doubleHome"]) {
		footerText = @"Overrides App Switcher + Apple Pay on Lock Screen. (Not recommended)";
	} else if ([activation isEqualToString:@"tripleHome"]) {
		footerText = @"Overrides Accessibility Shortcuts.";
	} else if ([activation isEqualToString:@"holdHome"]) {
		footerText = @"Overrides Siri.";
	}

	[groupSpecifier setProperty:footerText forKey:@"footerText"];
	[self reloadSpecifier:groupSpecifier];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	UIColor *tintColor = [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[[self class]]].onTintColor = tintColor;
	self.view.tintColor = tintColor;

	[self fetchGithubLogo];
	
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	NSString *activation = [prefs objectForKey:@"kActivation"] ?: @"tripleLock";
	[self updateFooterWithActivation:activation];
}

- (void)fetchGithubLogo {
	NSURL *url = [NSURL URLWithString:@"https://github.com/shalamand3r/shalamand3r.github.io/blob/main/CydiaIcon.png?raw=true"];
	[[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (data && !error) {
			UIImage *image = [UIImage imageWithData:data];
			if (image) {
				dispatch_async(dispatch_get_main_queue(), ^{
					PSSpecifier *githubSpecifier = [self specifierForID:@"GitHubCell"];
					if (githubSpecifier) {
						UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
						imageView.image = image;
						imageView.layer.cornerRadius = 7;
						imageView.layer.masksToBounds = YES;
						imageView.layer.contentsGravity = kCAGravityResizeAspectFill;
						
							UIScreen *screen = self.view.window.windowScene.screen ?: self.view.window.screen;
							CGFloat scale = screen ? screen.scale : 3.0;
							UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, scale);
						[imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
						UIImage *squircleImage = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
						
						[githubSpecifier setProperty:squircleImage forKey:@"iconImage"];
						[self reloadSpecifier:githubSpecifier];
					}
				});
			}
		}
	}] resume];
}

- (void)openGithub {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/shalamand3r/StandByNow"] options:@{} completionHandler:nil];
}

@end
