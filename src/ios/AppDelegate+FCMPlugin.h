//
//  AppDelegate+FCMPlugin.h
//  TestApp
//
//  Created by felipe on 12/06/16.
//
//

#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import <Cordova/CDVViewController.h>

@interface AppDelegate (FCMPlugin)

+ (NSData*)getLastPush;
+ (void) startRing:(Boolean)isVideo withName:(NSString *)name;
+ (void) stopRing:(Boolean) isMissed isVideo:(Boolean)isVideo from:(NSString *)name;
+ (void) stopRing;
@end
