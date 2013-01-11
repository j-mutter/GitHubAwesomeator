//
//  JMGitManager.m
//  GitHubAwesomeator
//
//  Created by Justin Mutter on 2012-08-09.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import "JMGitManager.h"
#import "JMGitRepoObject.h"
#import "JMAppDelegate.h"

@implementation JMGitManager

@synthesize gitLocation;
@synthesize gitRepos;
@synthesize gitRepoArray;

+ (JMGitManager *)sharedManager
{
    static dispatch_once_t pred;
    __strong static JMGitManager *manager = nil;
    dispatch_once(&pred, ^{
		manager = [[self alloc] init];
		
	});
	return manager;
}

- (id) init
{
	self = [super init];
	if (self){
		
		gitRepos = [NSMutableDictionary dictionary];
		gitRepoArray = [NSMutableArray array];
		
		if([self gitInit]){
			// first, load up any saved repos before scanning for new ones
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSArray *rootArray = [defaults objectForKey:@"SavedRepos"];
			if ([rootArray count] > 0){
				
			}
			
			[self findGitRepos];
		}else{
			NSLog(@"Unable to locate git executable");
			[(JMAppDelegate *)[[NSApplication sharedApplication] delegate] sendNotification:@"Error" withDescription:@"Unable to locate git executable"];
			[[NSApplication sharedApplication] terminate:@""];
		}
	}
	return self;
}

- (BOOL) gitInit
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
	if (self.gitLocation != nil) {
		return YES;
	}
	return NO;
	
}

-(void)findGitRepos{
	
	NSString *rootDirectory = NSHomeDirectory();
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:rootDirectory];
	
	NSString *filename;
	
	NSDate *startTime = [NSDate date];
	
	while (filename = [direnum nextObject]){
		
		if ([filename hasPrefix:@"."]){
			[direnum skipDescendants];
		}
		
		if([filename hasPrefix:@"Dropbox"]){
			[direnum skipDescendants];
		}
		
		NSRange libraryRange = [filename rangeOfString:@"Library/"];
		if (libraryRange.location != NSNotFound){
			[direnum skipDescendants];
		}
		
		NSRange librariesRange = [filename rangeOfString:@"Libraries/"];
		if (librariesRange.location != NSNotFound){
			[direnum skipDescendants];
		}
		
		if ([filename hasSuffix:@".git"]){
			
			NSArray *pathComponents = [filename pathComponents];
			NSString *repoName = [pathComponents objectAtIndex:([pathComponents count] -2)];
			
			NSString *fullPathToRepo = [rootDirectory stringByAppendingPathComponent:[filename stringByDeletingLastPathComponent]];
			
			[gitRepos setObject:fullPathToRepo forKey:repoName];
			JMGitRepoObject *foundRepo = [[JMGitRepoObject alloc] initWithRepoName:repoName Location:fullPathToRepo];
			[self addRepoObject:foundRepo];
			[direnum skipDescendants];
			
		}
		
	}
	NSDate *endTime = [NSDate date];
	
	NSTimeInterval elapsedTime = [endTime timeIntervalSinceDate:startTime];
	NSString *message = [NSString stringWithFormat:@"Found %ld repos in %f seconds", [gitRepos count], elapsedTime];
	NSLog(@"%@", message);
	[self sendNotification:@"Scan complete" withDescription:message];
	
}

-(void)runFullGitSuiteForRepo:(NSString *)repositoryName andBranch:(NSString *)branchName{
	// make sure we know where the repo is...
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repoName == %@ && isEnabled == YES", repositoryName];
	NSArray *filteredArray = [gitRepoArray filteredArrayUsingPredicate:predicate];
	JMGitRepoObject *matchingObject = nil;
	if ([filteredArray count] > 0){
		matchingObject = [filteredArray objectAtIndex:0];
	}else{
		NSLog(@"No matching repo found");
		[(JMAppDelegate *)[[NSApplication sharedApplication] delegate] sendNotification:@"Error" withDescription:@"No matching repo found"];
		return;
	}
	
	NSLog(@"%@", matchingObject.repoLocation);
	
	NSArray *commandsArray = [NSArray arrayWithObjects:@"checkout", @"submodule", @"submodule", @"pull", nil];
	NSArray *argumentsArray = [NSArray arrayWithObjects:branchName, @"init", @"update", @"--recurse-submodules", nil];
	
	NSMutableString *outputString;
	int result = 0;
	
	result = [self runGitCommand:[commandsArray objectAtIndex:0] atDirectoryPath:matchingObject.repoLocation withArguments:[NSArray arrayWithObject:[argumentsArray objectAtIndex:0]] theOutput:&outputString];
	
	if (result ==0){
		for (int i=1; i<[commandsArray count]; i++) {
			
			result = [self runGitCommand:[commandsArray objectAtIndex:i] atDirectoryPath:matchingObject.repoLocation withArguments:[NSArray arrayWithObject:[argumentsArray objectAtIndex:i]] theOutput:&outputString];
			
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

- (void) addRepoObject:(JMGitRepoObject *)newObject
{
	// only constraint is that the path is not already in use
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repoLocation == %@", newObject.repoLocation];
	NSArray *filteredArray = [gitRepoArray filteredArrayUsingPredicate:predicate];
	if ([filteredArray count] > 0){
		NSLog(@"Duplicate repo - not inserting");
	}else{
		[gitRepoArray addObject:newObject];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSMutableArray *repoArray = [defaults objectForKey:@"SavedRepos"];
		NSMutableData *data = [NSMutableData data];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		
		[archiver encodeObject:newObject];
		[archiver finishEncoding];
		
		
		
		[defaults synchronize];
	}
}

- (void) sendNotification:(NSString *)notification withDescription:(NSString *)description
{
	[(JMAppDelegate *)[[NSApplication sharedApplication] delegate] sendNotification:notification withDescription:description];
}

@end
