//
//  FootsieAppDelegate.m
//  Footsie
//
//  Created by Joe Groff on 12/12/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "FootsieAppDelegate.h"
#import "FootsieViewController.h"

@implementation FootsieAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
