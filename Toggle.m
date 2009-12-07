#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CaptainHook/CaptainHook.h>
#import <GraphicsServices/GraphicsServices.h>

#include <notify.h>

#define kSettingsChangeNotification "com.booleanmagic.rotationinhibitor.settingschange"
#define kSettingsFilePath "/User/Library/Preferences/com.booleanmagic.rotationinhibitor.plist"

static BOOL rotationEnabled;

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
	return rotationEnabled;
}

BOOL getStateFast()
{
	return rotationEnabled;
}

float getDelayTime()
{
	return 0.0f;
}

void setState(BOOL enable)
{
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:@kSettingsFilePath];
	if (!dict)
		dict = [[NSMutableDictionary alloc] init];
	[dict setObject:[NSNumber numberWithBool:enable] forKey:@"RotationEnabled"];
	NSData *data = [NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	[dict release];
	[data writeToFile:@kSettingsFilePath options:NSAtomicWrite error:NULL];
	notify_post(kSettingsChangeNotification);
}

#pragma mark UIApplication Hook

CHDeclareClass(UIApplication)

CHDeclareMethod2(void, UIApplication, handleEvent, GSEventRef, gsEvent, withNewEvent, UIEvent *, newEvent)
{
	if (gsEvent)
		if (GSEventGetType(gsEvent) == 50)
			if (!rotationEnabled)
				return;
	CHSuper2(UIApplication, handleEvent, gsEvent, withNewEvent, newEvent);
}

#pragma mark Constructor

CHConstructor
{	
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

