//
//  JMAppDelegate.h
//  GitHubAwesomeator
//
//  Created by Justin Mutter on 2012-07-31.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

#import "Growl/Growl.h"

#import "JMGitManager.h"


@interface JMAppDelegate : NSObject <NSApplicationDelegate, GrowlApplicationBridgeDelegate, NSUserNotificationCenterDelegate> {
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
}
@property (assign) IBOutlet NSWindow *window;

@property JMGitManager *gitManager;

-(void) sendNotification:(NSString *)title withDescription:(NSString *)description;

- (NSDictionary *) registrationDictionaryForGrowl;
- (void) growlNotificationWasClicked:(id)clickContext;

@end
