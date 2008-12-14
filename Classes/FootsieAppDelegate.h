#import <UIKit/UIKit.h>

@class FootsieViewController;

@interface FootsieAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    FootsieViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FootsieViewController *viewController;

@end

