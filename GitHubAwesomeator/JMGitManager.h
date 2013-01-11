//
//  JMGitManager.h
//  GitHubAwesomeator
//
//  Created by Justin Mutter on 2012-08-09.
//  Copyright (c) 2012 Justin Mutter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMGitManager : NSObject


@property NSString *gitLocation;
@property NSMutableDictionary *gitRepos;
@property NSMutableArray *gitRepoArray;

+ (JMGitManager *)sharedManager;

-(void)runFullGitSuiteForRepo:(NSString *)repositoryName andBranch:(NSString *)branchName;
-(int) runGitCommand:(NSString*) command theOutput:(NSMutableString **)output;
-(int) runGitCommand:(NSString*) command withArguments:(NSArray*) arguments theOutput:(NSMutableString **)output;
-(int) runGitCommand:(NSString*) command atDirectoryPath:(NSString*) path withArguments:(NSArray*) arguments theOutput:(NSMutableString **)output;

@end
