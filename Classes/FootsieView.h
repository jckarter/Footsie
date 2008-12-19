#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import "FootsieTargetView.h"

@class FootsieGameOverView;

@interface FootsieView : UIView
{
    NSArray *targets;
    NSMutableSet *goalTargets;
    FootsieTargetView *fromGoal, *toGoal;
    BOOL isCelebrating, isPaused, isEnded;
    NSTimer *pulseTimer;
    IBOutlet UIImageView *splashView;
    SystemSoundID bootSound, goalSound, endSound;
    unsigned score;

    FootsieGameOverView *endView;
    UIView *pauseView, *startView;

    UIView *activeInfoView;
}

@property(nonatomic, retain) NSArray *targets;
@property unsigned score;

@end
