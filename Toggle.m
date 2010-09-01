#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CaptainHook/CaptainHook.h>
#import <GraphicsServices/GraphicsServices.h>
#import <SpringBoard/SpringBoard.h>

#include <notify.h>

#define kSettingsChangeNotification "com.booleanmagic.rotationinhibitor.settingschange"
#define kSettingsFilePath "/User/Library/Preferences/com.booleanmagic.rotationinhibitor.plist"

#define IsOS4 (kCFCoreFoundationVersionNumber >= 478.61)

static BOOL rotationEnabled;

// OS 4.0

@interface SBOrientationLockManager : NSObject {
	int _override;
	int _lockedOrientation;
	int _overrideOrientation;
}
+ (id)sharedInstance;
- (void)lock:(int)lock;
- (void)unlock;
- (BOOL)isLocked;
- (int)lockOrientation;
- (void)setLockOverride:(int)override orientation:(int)orientation;
- (int)lockOverride;
- (void)updateLockOverrideForCurrentDeviceOrientation;
@end

@interface SBNowPlayingBar : NSObject {
	UIView *_containerView;
	UIButton *_orientationLockButton;
	UIButton *_prevButton;
	UIButton *_playButton;
	UIButton *_nextButton;
	SBIconLabel *_trackLabel;
	SBIconLabel *_orientationLabel;
	SBApplicationIcon *_nowPlayingIcon;
	SBApplication *_nowPlayingApp;
	int _scanDirection;
	BOOL _isPlaying;
	BOOL _isEnabled;
	BOOL _showingOrientationLabel;
}
- (void)_orientationLockHit:(id)sender;
- (void)_displayOrientationStatus:(BOOL)isLocked;
@end

@class SBAppSwitcherModel, SBAppSwitcherBarView;
@interface SBAppSwitcherController : NSObject {
	SBAppSwitcherModel *_model;
	SBNowPlayingBar *_nowPlaying;
	SBAppSwitcherBarView *_bottomBar;
	SBApplicationIcon *_pushedIcon;
	BOOL _editing;
}
+ (id)sharedInstance;
+ (id)sharedInstanceIfAvailable;
@end

CHDeclareClass(SBOrientationLockManager)
CHDeclareClass(SBAppSwitcherController)

CHDeclareClass(SBNowPlayingBar)

CHOptimizedMethod(1, self, void, SBNowPlayingBar, _orientationLockHit, id, sender)
{
	SBOrientationLockManager *lockManager = CHSharedInstance(SBOrientationLockManager);
	NSString *labelText;
	if ([lockManager isLocked]) {
		switch ([lockManager lockOrientation]) {
			case UIDeviceOrientationPortrait:
		    	[lockManager lock:UIDeviceOrientationLandscapeLeft];
				if ([lockManager lockOverride])
					[lockManager setLockOverride:0 orientation:UIDeviceOrientationUnknown];
		    	labelText = @"Landscape Left Orientation Locked";
		    	break;
			case UIDeviceOrientationLandscapeLeft:
		    	[lockManager lock:UIDeviceOrientationLandscapeRight];
				if ([lockManager lockOverride])
					[lockManager setLockOverride:0 orientation:UIDeviceOrientationUnknown];
		    	labelText = @"Landscape Right Orientation Locked";
		    	break;
			case UIDeviceOrientationLandscapeRight:
		    	[lockManager lock:UIDeviceOrientationPortraitUpsideDown];
				if ([lockManager lockOverride])
					[lockManager setLockOverride:0 orientation:UIDeviceOrientationUnknown];
		    	labelText = @"Upside Down Orientation Locked";
		    	break;
			default:
				[lockManager unlock];
				if ([lockManager lockOverride])
					[lockManager updateLockOverrideForCurrentDeviceOrientation];
		    	labelText = @"Orientation Unlocked";
		    	break;
		}
	} else {
    	[lockManager lock:UIDeviceOrientationPortrait];
		if ([lockManager lockOverride])
			[lockManager setLockOverride:0 orientation:UIDeviceOrientationPortrait];
		labelText = @"Portrait Orientation Locked";
	}
	BOOL isLocked = [lockManager isLocked];
	[CHIvar(self, _orientationLockButton, UIButton *) setSelected:isLocked];
	[self _displayOrientationStatus:isLocked];
	[CHIvar(self, _orientationLabel, UILabel *) setText:labelText];
}

#pragma mark Preferences

static void ReloadPreferences()
{
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@kSettingsFilePath];
	rotationEnabled = [[dict objectForKey:@"RotationEnabled"] boolValue];
	[dict release];
}

#pragma mark SBSettings Toggle

BOOL isCapable()
{
	return YES;
}

BOOL isEnabled()
{
	if (IsOS4)
		return ![CHSharedInstance(SBOrientationLockManager) isLocked];
	else
		return rotationEnabled;
}

BOOL getStateFast()
{
	if (IsOS4)
		return ![CHSharedInstance(SBOrientationLockManager) isLocked];
	else
		return rotationEnabled;
}

float getDelayTime()
{
	return 0.0f;
}

void setState(BOOL enable)
{
	if (IsOS4) {
		SBOrientationLockManager *lockManager = CHSharedInstance(SBOrientationLockManager);
		if (enable) {
			[lockManager unlock];
			if ([lockManager lockOverride])
				[lockManager updateLockOverrideForCurrentDeviceOrientation];
		} else {
			[lockManager lock:[lockManager lockOrientation]];
			if ([lockManager lockOverride])
				[lockManager setLockOverride:0 orientation:UIDeviceOrientationUnknown];
		}
		SBNowPlayingBar **nowPlayingBar = CHIvarRef([CHClass(SBAppSwitcherController) sharedInstanceIfAvailable], _nowPlaying, SBNowPlayingBar *);
		if (nowPlayingBar)
			[CHIvar(*nowPlayingBar, _orientationLockButton, UIButton *) setSelected:[lockManager isLocked]];
	} else {
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@kSettingsFilePath];
		if (!dict)
			dict = [[NSMutableDictionary alloc] init];
		[dict setObject:[NSNumber numberWithBool:enable] forKey:@"RotationEnabled"];
		NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
		[dict release];
		[data writeToFile:@kSettingsFilePath options:NSAtomicWrite error:NULL];
		notify_post(kSettingsChangeNotification);
	}
}

void invokeHoldAction()
{
	SBNowPlayingBar **nowPlayingBar = CHIvarRef([CHClass(SBAppSwitcherController) sharedInstance], _nowPlaying, SBNowPlayingBar *);
	if (nowPlayingBar)
		[*nowPlayingBar _orientationLockHit:nil];
}

// OS 3.x

CHDeclareClass(UIApplication)

CHOptimizedMethod(2, self, void, UIApplication, handleEvent, GSEventRef, gsEvent, withNewEvent, UIEvent *, newEvent)
{
	if (gsEvent)
		if (GSEventGetType(gsEvent) == 50)
			if (!rotationEnabled)
				return;
	CHSuper(2, UIApplication, handleEvent, gsEvent, withNewEvent, newEvent);
}

CHConstructor
{
	if (IsOS4) {
		if (CHLoadLateClass(SBOrientationLockManager)) {
			CHLoadLateClass(SBAppSwitcherController);
			CHLoadLateClass(SBNowPlayingBar);
			CHHook(1, SBNowPlayingBar, _orientationLockHit);
		}
	} else {
		CHLoadLateClass(UIApplication);
		CHHook(2, UIApplication, handleEvent, withNewEvent);
		ReloadPreferences();
		CFNotificationCenterAddObserver(
			CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(void (*)(CFNotificationCenterRef, void *, CFStringRef, const void *, CFDictionaryRef))ReloadPreferences,
			CFSTR(kSettingsChangeNotification),
			NULL,
			CFNotificationSuspensionBehaviorHold
		);
	}
}

