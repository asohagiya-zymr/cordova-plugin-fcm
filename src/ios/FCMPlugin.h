#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface FCMPlugin : CDVPlugin
{
    //NSString *notificationCallBack;
}

+ (FCMPlugin *) fcmPlugin;
- (void)ready:(CDVInvokedUrlCommand*)command;
- (void)getToken:(CDVInvokedUrlCommand*)command;
- (void)subscribeToTopic:(CDVInvokedUrlCommand*)command;
- (void)unsubscribeFromTopic:(CDVInvokedUrlCommand*)command;
- (void)registerNotification:(CDVInvokedUrlCommand*)command;
- (void)notifyOfMessage:(NSData*) payload;
- (void)notifyOfAction:(NSString*)actionIdentifier :(NSString*)uuid;
- (void)notifyOfTokenRefresh:(NSString*) token;
- (void)appEnterBackground;
- (void)appEnterForeground;
- (void)logError:(CDVInvokedUrlCommand*)command;
- (void)log:(CDVInvokedUrlCommand*)command;
- (void)setString:(CDVInvokedUrlCommand*)command;
- (void)setBool:(CDVInvokedUrlCommand*)command;
- (void)setDouble:(CDVInvokedUrlCommand*)command;
- (void)setFloat:(CDVInvokedUrlCommand*)command;
- (void)setInt:(CDVInvokedUrlCommand*)command;
- (void)setCrashlyticsUserId:(CDVInvokedUrlCommand*)command;

//Call management functions
- (void) callStartRing:(CDVInvokedUrlCommand*)command;
- (void) callStopRing:(CDVInvokedUrlCommand*)command;

@end
