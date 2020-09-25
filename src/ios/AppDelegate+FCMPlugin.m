//
//  AppDelegate+FCMPlugin.m
//  TestApp
//
//  Created by felipe on 12/06/16.
//
//
#import "AppDelegate+FCMPlugin.h"
#import "FCMPlugin.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "Firebase.h"

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

@import FirebaseInstanceID;
@import FirebaseMessaging;

// Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
// running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
// devices running iOS 10 and above.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface AppDelegate () <FIRMessagingDelegate>
@end
#endif

// Copied from Apple's header in case it is missing in some cases (e.g. pre-Xcode 8 builds).
#ifndef NSFoundationVersionNumber_iOS_9_x_Max
#define NSFoundationVersionNumber_iOS_9_x_Max 1299
#endif

@implementation AppDelegate (MCPlugin)

static NSData *lastPush;
static Boolean isRinging;
static Boolean stopRinging;
static AppDelegate *this;
static UNNotificationCategory* incomingCallCategory;
static NSURL *ringtoneURL;
static SystemSoundID ringtoneID;

NSString *const kGCMMessageIDKey = @"gcm.message_id";

//Method swizzling
+ (void)load
{
    Method original =  class_getInstanceMethod(self, @selector(application:didFinishLaunchingWithOptions:));
    Method custom =    class_getInstanceMethod(self, @selector(application:customDidFinishLaunchingWithOptions:));
    method_exchangeImplementations(original, custom);
}

- (BOOL)application:(UIApplication *)application customDidFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [self application:application customDidFinishLaunchingWithOptions:launchOptions];

    NSLog(@"DidFinishLaunchingWithOptions");
    isRinging = false;
    stopRinging = false;
    this = self;
    //Set notification categories
    UNNotificationAction* acceptAction = [UNNotificationAction actionWithIdentifier:@"INCOMING_CALL_ACCEPT_ACTION" title:@"Accept" options:(UNNotificationActionOptionForeground)];
    UNNotificationAction* declineAction = [UNNotificationAction actionWithIdentifier:@"INCOMING_CALL_DECLINE_ACTION" title:@"Decline" options:(UNNotificationActionOptionDestructive)];
    UNNotificationCategoryOptions notificationCategoryOptions = UNNotificationCategoryOptionCustomDismissAction;
    if (@available(iOS 11.0, *)) {
        notificationCategoryOptions = (UNNotificationCategoryOptionCustomDismissAction | UNNotificationCategoryOptionHiddenPreviewsShowSubtitle | UNNotificationCategoryOptionHiddenPreviewsShowTitle);
    }
    incomingCallCategory = [UNNotificationCategory categoryWithIdentifier:@"FCM_INCOMING_CALL" actions:[NSArray<UNNotificationAction *> arrayWithObjects:acceptAction, declineAction, nil] intentIdentifiers:@[] options:notificationCategoryOptions];
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {
        NSMutableSet<UNNotificationCategory *> *newCategorySet = [[NSMutableSet<UNNotificationCategory *> alloc] initWithSet:categories];
        [newCategorySet addObject:incomingCallCategory];
        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:newCategorySet];
    }];
    ringtoneURL = [NSBundle.mainBundle URLForResource:@"Ringtone" withExtension:@"caf"];
    CFURLRef ringtoneCFURL = (CFURLRef)CFBridgingRetain(ringtoneURL);
    OSStatus error = AudioServicesCreateSystemSoundID(ringtoneCFURL, &ringtoneID);
    
    // Register for remote notifications. This shows a permission dialog on first run, to
    // show the dialog at a more appropriate time move this registration accordingly.
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        // iOS 7.1 or earlier. Disable the deprecation warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType allNotificationTypes =
        (UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert |
         UIRemoteNotificationTypeBadge);
        [application registerForRemoteNotificationTypes:allNotificationTypes];
#pragma clang diagnostic pop
    } else {
        // iOS 8 or later
        // [START register_for_notifications]
        if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        } else {
            // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
            // For iOS 10 data message (sent via FCM)
            [FIRMessaging messaging].delegate = self;
#endif
        }
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        // [END register_for_notifications]
    }

    // [START configure_firebase]
    [FIRApp configure];
    // [END configure_firebase]
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveWillPresentNotification:)
                                                 name:@"AppPresentNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotificationAction:)
                                                 name:@"AppNotificationAction"
                                               object:nil];
    return YES;
}

+ (NSString *)hexadecimalStringFromData:(NSData *)data
{
  NSUInteger dataLength = data.length;
  if (dataLength == 0) {
    return nil;
  }

  const unsigned char *dataBuffer = (const unsigned char *)data.bytes;
  NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
  for (int i = 0; i < dataLength; ++i) {
    [hexString appendFormat:@"%02x", dataBuffer[i]];
  }
  return [hexString copy];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { 
    NSString *str = [NSString stringWithFormat:@"Device Token=%@",deviceToken];
    NSLog(@"This is device token%@", deviceToken);
}

//Incoming call presentation functions

+ (void) startRing:(Boolean)isVideo withName:(NSString *)name {
    
    //Mutex, prevent running start ring twice
    @synchronized (self) {
        if(isRinging) {
            return;
        }
        
        isRinging = true;
    }
    [this ring:isVideo withName:name withCount:0];
}

+ (void) stopRing:(Boolean) isMissed isVideo:(Boolean)isVideo from:(NSString *)name {
    stopRinging = true;
    if(isMissed) {
        [this missedCallNotificaion:isVideo from:name];
    }
}

+ (void) stopRing {
    stopRinging = true;
}

- (void) missedCallNotificaion:(Boolean) isVideo from:(NSString*) name {
    UNMutableNotificationContent *objNotificationContent = [[UNMutableNotificationContent alloc] init];
    objNotificationContent.title = [NSString localizedUserNotificationStringForKey:isVideo ? @"Missed Call" : @"Missed Video Call" arguments:nil];
    objNotificationContent.body = [NSString localizedUserNotificationStringForKey:name arguments:nil];
    objNotificationContent.sound = [UNNotificationSound defaultSound];
    objNotificationContent.badge = @([[UIApplication sharedApplication] applicationIconBadgeNumber] + 1);
    UNTimeIntervalNotificationTrigger *trigger =  [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1f repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[@"missedcall" stringByAppendingString:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]]] content:objNotificationContent trigger:trigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to send missed call notification!");
        }
    }];
}

- (void) ring:(Boolean)isVideo withName:(NSString *)name withCount:(int)count {
    dispatch_time_t interval = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC));
    
    int numLoops = 8;
    
    @synchronized (self) {
        if(stopRinging || count >= numLoops) {
            isRinging = false;
            stopRinging = false;
            [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:[NSArray arrayWithObject:@"incomingcall"]];
            if(count >= numLoops) {
                [self missedCallNotificaion:isVideo from:name];
            }
            return;
        }
    }
    
    //TODO: set different title for video calls.
    UNMutableNotificationContent *objNotificationContent = [[UNMutableNotificationContent alloc] init];
    objNotificationContent.title = [NSString localizedUserNotificationStringForKey:isVideo ? @"Incoming Call" : @"Incoming Video Call" arguments:nil];
    objNotificationContent.body = [NSString localizedUserNotificationStringForKey:name arguments:nil];
    objNotificationContent.categoryIdentifier = incomingCallCategory.identifier;
    objNotificationContent.sound = [UNNotificationSound soundNamed:@"Blank.caf"];
    UNTimeIntervalNotificationTrigger *trigger =  [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1f repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"incomingcall" content:objNotificationContent trigger:trigger];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to send incoming call notification");
        }
        else {
            if(ringtoneURL != nil) {
                AudioServicesPlayAlertSound(ringtoneID);
            }
        }
    }];
    
    dispatch_after(interval, dispatch_get_main_queue(), ^(void){
        [self ring:isVideo withName:name withCount:count+1];
    });
}

// [START message_handling]

// Handle incoming notification messages while app is in the foreground.
- (void) receiveWillPresentNotification:(NSNotification *) notification {
    NSDictionary *broadcastUserInfo = notification.userInfo;
    UNNotification *broadcastNotification = [broadcastUserInfo objectForKey:@"notification"];
    
    // Print message ID.
    NSDictionary *userInfo = broadcastNotification.request.content.userInfo;
    if (userInfo[kGCMMessageIDKey]) {
        NSLog(@"Message ID 1: %@", userInfo[kGCMMessageIDKey]);
    }
    
    // Print full message.
    NSLog(@"%@", userInfo);
    
    NSError *error;
    NSDictionary *userInfoMutable = [userInfo mutableCopy];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfoMutable
                                                       options:0
                                                         error:&error];
    [FCMPlugin.fcmPlugin notifyOfMessage:jsonData];
    
    // Change this to your preferred presentation option
    //completionHandler(UNNotificationPresentationOptionNone);
}

// Handle notification messages after display notification is tapped by the user.
- (void) receiveNotificationAction:(NSNotification *) notification {
    NSDictionary *broadcastUserInfo = notification.userInfo;
    UNNotificationResponse *response = [broadcastUserInfo objectForKey:@"notification"];
    
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    NSString *actionIdentifier = response.actionIdentifier;
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;
    if (userInfo[kGCMMessageIDKey]) {
        NSLog(@"Message ID 2: %@", userInfo[kGCMMessageIDKey]);
    }
    
    if([categoryIdentifier isEqualToString:incomingCallCategory.identifier]) {
        [FCMPlugin.fcmPlugin notifyOfAction:actionIdentifier];
    }
    
    // Print full message.
    NSLog(@"aaa%@", userInfo);
    
    NSError *error;
    NSDictionary *userInfoMutable = [userInfo mutableCopy];
    

        NSLog(@"New method with push callback: %@", userInfo);
        
        [userInfoMutable setValue:@(YES) forKey:@"wasTapped"];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfoMutable
                                                           options:0
                                                             error:&error];
        NSLog(@"APP WAS CLOSED DURING PUSH RECEPTION Saved data: %@", jsonData);
        lastPush = jsonData;

    
    //completionHandler();
}

// Receive background notification
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo 
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:7];
//    notification.alertBody = @"BG notification received!";
//    notification.timeZone = [NSTimeZone defaultTimeZone];
//    notification.soundName = UILocalNotificationDefaultSoundName;
//
//    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    
    if([(NSString *)userInfo[@"type"] isEqualToString:@"incomingCall"]) {
        dispatch_time_t executionTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC));
        dispatch_after(executionTime, dispatch_get_main_queue(), ^(void){
            completionHandler(UIBackgroundFetchResultNewData);
        });
        [AppDelegate startRing:(Boolean)userInfo[@"isVideo"] withName:(NSString *)userInfo[@"name"]];
    }
    else if([(NSString *)userInfo[@"type"] isEqualToString:@"stopIncomingCall"] && isRinging) {
        [AppDelegate stopRing:true isVideo:(Boolean)userInfo[@"isVideo"] from:(NSString *)userInfo[@"name"]];
    }
    else {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    
}

// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification
{
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    [FCMPlugin.fcmPlugin notifyOfTokenRefresh:refreshedToken];
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];

    // TODO: If necessary send token to appliation server.
}
// [END refresh_token]

// [START connect_to_fcm]
- (void)connectToFcm
{
    
    // Won't connect since there is no token
    if (![[FIRInstanceID instanceID] token]) {
        return;
    }
    
    // Disconnect previous FCM connection if it exists.
    [[FIRMessaging messaging] disconnect];
    
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
            [[FIRMessaging messaging] subscribeToTopic:@"/topics/ios"];
            [[FIRMessaging messaging] subscribeToTopic:@"/topics/all"];
        }
    }];
}
// [END connect_to_fcm]

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"app become active");
    [FCMPlugin.fcmPlugin appEnterForeground];
    [self connectToFcm];
}

// [START disconnect_from_fcm]
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"app entered background");
    [[FIRMessaging messaging] disconnect];
    [FCMPlugin.fcmPlugin appEnterBackground];
    NSLog(@"Disconnected from FCM");
}
// [END disconnect_from_fcm]

+(NSData*)getLastPush
{
    NSData* returnValue = lastPush;
    lastPush = nil;
    return returnValue;
}


@end
