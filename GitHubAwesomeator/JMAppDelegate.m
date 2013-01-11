//
//  JMAppDelegate.m
//  WTFGITHUB
//
//  Created by Justin Mutter on 2012-07-31.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import "JMAppDelegate.h"


@implementation JMAppDelegate

@synthesize window;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{	
	[JMGitManager sharedManager];
	
	NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
	[appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{	

	self.repos = [JMGitManager sharedManager].gitRepoArray;
	[GrowlApplicationBridge setGrowlDelegate:self];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    NSLog(@"Opening %@", url);
	
	NSString *repoName = [url host];
	
	NSString *branchToCheckout = [[url path] substringFromIndex:1];

	[[JMGitManager sharedManager] runFullGitSuiteForRepo:repoName andBranch:branchToCheckout];
	
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSDictionary *registrationDictionary;
	NSArray *allGrowlNotifications = [NSArray arrayWithObjects:@"git-alert", nil];
	NSArray *enabledGrowlNotifications = [NSArray arrayWithObjects:@"git-alert", nil];
	NSArray *notifications = [NSArray arrayWithObjects:allGrowlNotifications, enabledGrowlNotifications, nil];
	NSArray *keys = [NSArray arrayWithObjects:GROWL_NOTIFICATIONS_ALL, GROWL_NOTIFICATIONS_DEFAULT, nil];
	
	registrationDictionary = [NSDictionary dictionaryWithObjects:notifications forKeys:keys];
	
	return registrationDictionary;
}

- (void) growlNotificationWasClicked:(id)clickContext
{
	NSLog(@"%@", clickContext);
}

-(void) sendNotification:(NSString *)title withDescription:(NSString *)description{
	
	SInt32 major, minor;
	Gestalt(gestaltSystemVersionMajor, &major);
	Gestalt(gestaltSystemVersionMinor, &minor);
	
	NSString *systemVersionString = [NSString stringWithFormat:@"%d.%d",
							   major, minor];
	
	NSDecimalNumber *versionNumber = [NSDecimalNumber decimalNumberWithString:systemVersionString];
	
	
	if([versionNumber isGreaterThanOrEqualTo:[NSDecimalNumber decimalNumberWithString:@"10.8"]]){
		NSLog(@"Mountain Lion or newer - hit the Notification Center, right in the ovaries");
		NSUserNotification *note = [[NSUserNotification alloc] init];
		note.title = title;
		note.informativeText = description;
		[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
		
	}else{
		NSLog(@"Too old, fall back to Growl. /sad trombone");
		NSDictionary *growlMessageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"git-alert", GROWL_NOTIFICATION_NAME,
											 title, GROWL_NOTIFICATION_TITLE,
											 description, GROWL_NOTIFICATION_DESCRIPTION,
											 @"GitHubAwesomeator", GROWL_APP_NAME,
											 nil];
		[GrowlApplicationBridge notifyWithDictionary:growlMessageDictionary];
	}
	

}

-(void)awakeFromNib{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:statusMenu];
	[statusItem setImage:[NSImage imageNamed:@"icon_16x16.png"]];
	[statusItem setHighlightMode:YES];
}


@end
