#import <UIKit/UIKit.h>
#import "FootsieTargetView.h"

@interface FootsieView : UIView
{
    NSArray *targets;
    NSMutableSet *goalTargets;
    FootsieTargetView *fromGoal, *toGoal;
    BOOL isPlaying;
    NSTimer *pulseTimer;
    IBOutlet UIImageView *splashView;
}

@property(nonatomic, retain) NSArray *targets;

@end
