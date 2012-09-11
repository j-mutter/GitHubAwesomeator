//
//  JMAppDelegate.m
//  WTFGITHUB
//
//  Created by Justin Mutter on 2012-07-31.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import "JMAppDelegate.h"


@implementation JMAppDelegate

@synthesize gitLocation;
@synthesize gitRepos;

@synthesize window;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	
	gitRepos = [[NSMutableDictionary alloc] init];
	[self findGitRepos];
	
	NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
	[appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
	[GrowlApplicationBridge setGrowlDelegate:self];
	[self gitInit];
	
	
}


- (void)handleGetURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    NSLog(@"Opening %@", url);
	
	NSString *repoName = [url host];
	
	NSString *branchToCheckout = [[url path] substringFromIndex:1];

	[self runFullGitSuiteForRepo:repoName andBranch:branchToCheckout];
	
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

- (void) gitInit
{
	
	NSArray *possiblePaths = [NSArray arrayWithObjects:@"/usr/bin/git", nil];
	
	NSArray *arguments;
	arguments = [NSArray arrayWithObjects: @"--version", nil];
	
	for(int i = 0; i<[possiblePaths count]; i++){
		
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath: [possiblePaths objectAtIndex:i]];
		
		[task setArguments: arguments];
		
		NSPipe *pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		
		NSFileHandle *file = [pipe fileHandleForReading];
		
		[task launch];
		[task waitUntilExit];
		
		NSData *data;
		data = [file readDataToEndOfFile];
		
		NSString *string;
		string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		if([string length] > 0){
			NSLog (@"Git found at: %@", [possiblePaths objectAtIndex:i]);
			self.gitLocation = [possiblePaths objectAtIndex:i];
			continue;
		}
	}
	
}

- (int) runGitCommand:(NSString*) command theOutput:(NSMutableString **)output
{
	return [self runGitCommand:command atDirectoryPath:nil withArguments:nil theOutput:output];
	
}

- (int) runGitCommand:(NSString*) command withArguments:(NSArray*) arguments theOutput:(NSMutableString **)output
{
	return [self runGitCommand:command atDirectoryPath:nil withArguments:arguments theOutput:output];
}

- (int) runGitCommand:(NSString*) command atDirectoryPath:(NSString*) path withArguments:(NSArray*) arguments theOutput:(NSMutableString **)output
{
	NSMutableString *theOutput;
	int exitStatus;
	
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:[self gitLocation]];
	
	if( ( path != nil ) && ( [path length] > 0 ) ){
		[task setCurrentDirectoryPath:path];
	}
	
	//NSLog(@"Path is %@", path);
	
	NSArray *fullArguments;
	if( ( arguments != nil ) && ( [arguments count] > 0 ) ){
		fullArguments = [[NSArray arrayWithObject:command] arrayByAddingObjectsFromArray:arguments];
	}else{
		fullArguments = [NSArray arrayWithObject:command];
	}
	[task setArguments:fullArguments];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[task launch];
	[task waitUntilExit];
	
	NSData *data;
	data = [file readDataToEndOfFile];
	
	theOutput = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	*output = theOutput;
	
	exitStatus = [task terminationStatus];

	return exitStatus;
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

-(void)runFullGitSuiteForRepo:(NSString *)repositoryName andBranch:(NSString *)branchName{
	// make sure we know where the repo is...
	NSString *repoLocation = [gitRepos objectForKey:repositoryName];
	NSLog(@"%@", repoLocation);

	NSArray *commandsArray = [NSArray arrayWithObjects:@"checkout", @"submodule", @"submodule", @"pull", nil];
	NSArray *argumentsArray = [NSArray arrayWithObjects:branchName, @"init", @"update", @"--recurse-submodules", nil];
	
	NSMutableString *outputString;
	int result = 0;

	result = [self runGitCommand:[commandsArray objectAtIndex:0] atDirectoryPath:repoLocation withArguments:[NSArray arrayWithObject:[argumentsArray objectAtIndex:0]] theOutput:&outputString];
	
	if (result ==0){
		for (int i=1; i<[commandsArray count]; i++) {
			
			result = [self runGitCommand:[commandsArray objectAtIndex:i] atDirectoryPath:repoLocation withArguments:[NSArray arrayWithObject:[argumentsArray objectAtIndex:i]] theOutput:&outputString];
			
			if(result != 0){
				NSLog(@"Error running git command: %@ %@ \n\t%@", [commandsArray objectAtIndex:i], [argumentsArray objectAtIndex:i], outputString);
				break;
			}
			
		}
		if (result == 0){
			[self sendNotification:@"Check out" withDescription:[NSString stringWithFormat:@"%@ checked out successfully",branchName]];
		}else{
			[self sendNotification:@"Check out with Errors" withDescription:[NSString stringWithFormat:@"Errors checking out %@", branchName]];
		}
		
	}else{
		NSLog(@"Error checking out branch %@ \n\t%@", branchName, outputString);
		[self sendNotification:@"Check out failed" withDescription:[NSString stringWithFormat:@"Failed to check out  %@", branchName]];
	}
	
}

-(void)findGitRepos{

	NSString *rootDirectory = [NSHomeDirectory() stringByAppendingString:@"/Projects"];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:rootDirectory];
	
	NSString *filename;
	
	while (filename = [direnum nextObject]){
		
		if ([filename hasSuffix:@".git"]){
			NSRange libraryRange = [filename rangeOfString:@"/Library/"];
			if (libraryRange.location != NSNotFound){
				continue;
			}
			NSRange librariesRange = [filename rangeOfString:@"/Libraries/"];
			if (librariesRange.location != NSNotFound){
				continue;
			}
			
			NSMutableArray *repoParts = [NSMutableArray arrayWithArray:[filename componentsSeparatedByString:@"/"]];
			[repoParts removeLastObject];
			NSString *repoName = [repoParts objectAtIndex:([repoParts count] -1)];
			
			NSString *repoPath = [repoParts componentsJoinedByString:@"/"];
			NSString *fullPathToRepo = [NSHomeDirectory() stringByAppendingString:@"/Projects/"];
			fullPathToRepo = [fullPathToRepo stringByAppendingString:repoPath];
			
			[gitRepos setObject:fullPathToRepo forKey:repoName];
			
		}
		
	}

}

-(void)awakeFromNib{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setMenu:statusMenu];
	[statusItem setImage:[NSImage imageNamed:@"icon_16x16.png"]];
	[statusItem setHighlightMode:YES];
}


@end
