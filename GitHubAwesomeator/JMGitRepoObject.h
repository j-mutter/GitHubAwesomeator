//
//  JMGitRepoObject.h
//  GitHubAwesomeator
//
//  Created by Justin Mutter on 2012-10-19.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMGitRepoObject : NSObject <NSCoding>

@property NSString *repoName;
@property NSString *repoLocation;
@property BOOL		isEnabled;

+ (NSArray *) repoObjectsWithDictionary:(NSDictionary *)dictionary;

- (id) initWithRepoName:(NSString *)name Location:(NSString *)location;
- (id) initWithRepoName:(NSString *)name Location:(NSString *)location Enabled:(BOOL)enabled;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;



@end
