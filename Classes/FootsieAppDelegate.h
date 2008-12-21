#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@class FootsieViewController;
@class FootsieInstructionsViewController;

@interface FootsieAppDelegate : NSObject <UIApplicationDelegate, ABNewPersonViewControllerDelegate> {
    UIWindow *window;
    FootsieViewController *viewController;
    FootsieInstructionsViewController *instructionsViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FootsieViewController *viewController;
@property (nonatomic, retain) IBOutlet FootsieInstructionsViewController *instructionsViewController;

- (IBAction)showInstructions:(id)sender;
- (IBAction)addContact:(id)sender;

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController
    didCompleteWithNewPerson:(ABRecordRef)person;

@end

