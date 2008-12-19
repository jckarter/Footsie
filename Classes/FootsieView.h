#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import "FootsieTargetView.h"

@class FootsieGameOverView;
@class FootsiePausedView;

@interface FootsieView : UIView
{
    NSArray *targets;
    NSMutableSet *p1GoalTargets, *p2GoalTargets, *fromGoals, *toGoals;
    BOOL isCelebrating, isPaused, isEnded, isP1;
    NSTimer *pulseTimer;
    IBOutlet UIImageView *splashView;
    SystemSoundID bootSound, goalSound, endSound;
    unsigned score;

    FootsieGameOverView *endView;
    FootsiePausedView *pauseView;
    UIView *startView;

    UIView *activeInfoView;
}

@property(nonatomic, retain) NSArray *targets;
@property unsigned score;

@end
