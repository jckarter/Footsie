#import "FootsieAppDelegate.h"
#import "FootsieViewController.h"
#import "FootsieInstructionsViewController.h"

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

- (IBAction)showInstructions:(id)sender
{
    [viewController presentModalViewController:instructionsViewController animated:YES];
}

- (IBAction)addContact:(id)sender
{
    ABNewPersonViewController *newPerson = [[[ABNewPersonViewController alloc] init] autorelease];
    newPerson.newPersonViewDelegate = self;

    UINavigationController *nav = [[[UINavigationController alloc]
        initWithRootViewController:newPerson
    ] autorelease];

    [viewController presentModalViewController:nav animated:YES];
}

- (void)newPersonViewController:(ABNewPersonViewController *)newPerson
    didCompleteWithNewPerson:(ABRecordRef)whatevs
{
    [viewController dismissModalViewControllerAnimated:YES];
}

@end
