#import "FootsieAppDelegate.h"
#import "FootsieViewController.h"

@implementation FootsieAppDelegate

@synthesize window, viewController, instructionsViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}

- (void)dealloc
{
    [viewController release];
    [instructionsViewController release];
    [window release];
    [super dealloc];
}

@end
