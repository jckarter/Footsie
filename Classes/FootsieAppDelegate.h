#import <UIKit/UIKit.h>

@class FootsieViewController;
@class FootsieInstructionsViewController;

@interface FootsieAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    FootsieViewController *viewController;
    FootsieInstructionsViewController *instructionsViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FootsieViewController *viewController;
@property (nonatomic, retain) IBOutlet FootsieInstructionsViewController *instructionsViewController;

@end

