//
//  JMGitRepoObject.m
//  GitHubAwesomeator
//
//  Created by Justin Mutter on 2012-10-19.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import "JMGitRepoObject.h"

@implementation JMGitRepoObject

@synthesize repoName;
@synthesize repoLocation;
@synthesize isEnabled;

+ (NSArray *) repoObjectsWithDictionary:(NSDictionary *)dictionary
{
	NSMutableArray *repoObjects = [NSArray array];
	
	for (NSString *key in dictionary){
		JMGitRepoObject *newObject = [[JMGitRepoObject alloc] initWithRepoName:key Location:[dictionary valueForKey:key]];
		[repoObjects addObject:newObject];
	}
	
	return repoObjects;
}


- (id) initWithRepoName:(NSString *)name Location:(NSString *)location
{
	return [self initWithRepoName:name Location:location Enabled:YES];
}

- (id) initWithRepoName:(NSString *)name Location:(NSString *)location Enabled:(BOOL)enabled
{
	self = [super init];
	if(self){
		self.repoName = name;
		self.repoLocation = location;
		self.isEnabled = enabled;
	}
	return self;
}

- (id) initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self){
		self.repoName = [decoder decodeObjectForKey:@"repoName"];
		self.repoLocation = [decoder decodeObjectForKey:@"repoLocation"];
		self.isEnabled = [decoder decodeBoolForKey:@"isEnabled"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:repoName forKey:@"repoName"];
	[encoder encodeObject:repoLocation forKey:@"repoLocation"];
	[encoder encodeBool:isEnabled forKey:@"isEnabled"];
}

@end
