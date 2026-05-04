#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "StandByNowRootListController.h"

#define BUNDLE @"com.shalamand3r.standbynow"

static UIImage *_cachedGithubIcon = nil;

@implementation StandByNowRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
		
		for (PSSpecifier *spec in _specifiers) {
			if ([[spec propertyForKey:@"id"] isEqualToString:@"GitHubCell"]) {
				if (_cachedGithubIcon) {
					[spec setProperty:_cachedGithubIcon forKey:@"iconImage"];
				} else {
					UIGraphicsBeginImageContextWithOptions(CGSizeMake(29, 29), NO, 0);
					UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					[spec setProperty:blank forKey:@"iconImage"];
				}
			}
		}
	}
	return _specifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
	PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
	
	if ([[specifier propertyForKey:@"id"] isEqualToString:@"GitHubCell"]) {
		if (!_cachedGithubIcon) {
			UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell.imageView viewWithTag:1234];
			if (!spinner) {
				spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
				spinner.tag = 1234;
				[cell.imageView addSubview:spinner];
				
				spinner.translatesAutoresizingMaskIntoConstraints = NO;
				[NSLayoutConstraint activateConstraints:@[
					[spinner.centerXAnchor constraintEqualToAnchor:cell.imageView.centerXAnchor],
					[spinner.centerYAnchor constraintEqualToAnchor:cell.imageView.centerYAnchor]
				]];
			}
			[spinner startAnimating];
		} else {
			UIView *spinner = [cell.imageView viewWithTag:1234];
			if (spinner) {
				[spinner removeFromSuperview];
			}
		}
	}
	
	return cell;
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
	
	UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
	[haptic impactOccurred];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	UIColor *tintColor = [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0];
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[[self class]]].onTintColor = tintColor;
	self.view.tintColor = tintColor;

	if (!_cachedGithubIcon) {
		[self fetchGithubLogo];
	}
}

- (void)fetchGithubLogo {
	if (_cachedGithubIcon) return;
	NSURL *url = [NSURL URLWithString:@"https://github.com/shalamand3r/shalamand3r.github.io/blob/main/CydiaIcon.png?raw=true"];
	[[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		if (data && !error) {
			UIImage *image = [UIImage imageWithData:data];
			if (image) {
				UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
				imageView.image = image;
				imageView.layer.cornerRadius = 7;
				imageView.layer.masksToBounds = YES;
				imageView.layer.contentsGravity = kCAGravityResizeAspectFill;
				
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
				CGFloat scale = [UIScreen mainScreen].scale;
#pragma clang diagnostic pop
				UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, scale);
				[imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
				UIImage *squircleImage = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
				
				_cachedGithubIcon = squircleImage;
				dispatch_async(dispatch_get_main_queue(), ^{
					PSSpecifier *githubSpecifier = [self specifierForID:@"GitHubCell"];
					if (githubSpecifier) {
						[githubSpecifier setProperty:squircleImage forKey:@"iconImage"];
						[self reloadSpecifier:githubSpecifier];
						
						NSIndexPath *indexPath = [self indexPathForSpecifier:githubSpecifier];
						if (indexPath) {
							UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
							if (cell) {
								UIView *spinner = [cell.imageView viewWithTag:1234];
								if (spinner) {
									[spinner removeFromSuperview];
								}
							}
						}
					}
				});
			}
		}
	}] resume];
}

- (void)openStandBy {
	UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
	[haptic impactOccurred];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.shalamand3r.standbynow/TriggerStandBy"), NULL, NULL, YES);
}

- (void)openGithub {
	UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
	[haptic impactOccurred];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/shalamand3r/StandByNow"] options:@{} completionHandler:nil];
}

@end

@implementation StandByNowActivationController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
		NSString *activation = [prefs objectForKey:@"kActivation"] ?: @"tripleLock";
		[self updateFooterWithActivation:activation];
	});
}

- (void)updateFooterWithActivation:(NSString *)activation {
	PSSpecifier *groupSpecifier = [self specifierForID:@"ActivationFooterGroup"];
	if (!groupSpecifier) return;

	NSString *footerText = @"";

	if ([activation isEqualToString:@"tripleLock"]) {
		footerText = @"Lock Button Triple Click will override your Accessibility Shortcuts.";
	} else if ([activation isEqualToString:@"doubleLock"]) {
		footerText = @"Lock Button Double Click will override the Apple Pay shortcut.";
	} else if ([activation isEqualToString:@"holdLock"]) {
		footerText = @"Lock Button Hold will override the power off gesture.";
	} else if ([activation isEqualToString:@"volume"]) {
		footerText = @"Volume Up + Down is a safe option that won't interfere with any system gestures.";
	} else if ([activation isEqualToString:@"doubleHome"]) {
		footerText = @"Home Button Double Click will override the App Switcher and Apple Pay. This is NOT recommended.";
	} else if ([activation isEqualToString:@"tripleHome"]) {
		footerText = @"Home Button Triple Click will override your Accessibility Shortcuts.";
	} else if ([activation isEqualToString:@"holdHome"]) {
		footerText = @"Home Button Hold will override Siri.";
	}

	[groupSpecifier setProperty:footerText forKey:@"footerText"];
	[[self table] reloadData];
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *specs = [[super specifiers] mutableCopy];
		
		for (PSSpecifier *spec in specs) {
			if (spec.cellType == PSGroupCell) {
				[spec setProperty:@"ActivationFooterGroup" forKey:@"id"];
				break;
			}
		}
		
		_specifiers = [specs copy];
	}
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	NSString *activation = [prefs objectForKey:@"kActivation"] ?: @"tripleLock";
	[self updateFooterWithActivation:activation];
}

@end
