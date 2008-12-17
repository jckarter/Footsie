#import "FootsieView.h"
#import "FootsiePulseView.h"
#import "misc.h"
#include <stdlib.h>
#include <math.h>

@interface FootsieView ()

- (void)_updateForTouches:(NSSet*)touches;
- (BOOL)_goalsReached;
- (void)_celebrateGoalsReached;
- (void)_moveRandomGoalAfterDelay:(NSTimer*)t;
- (UIColor*)_backgroundColor;

- (FootsiePulseView*)_pulseFromView:(UIView*)view color:(UIColor*)color direction:(FootsiePulseViewDirection)direction;

- (void)_pulseTimerTick:(NSTimer*)timer;
- (void)_pulseAnimationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context;

- (void)_splashViewFadeOutDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context;

- (void)addGoal:(FootsieTargetView*)t;
- (void)removeGoal:(FootsieTargetView*)t;
- (void)moveGoal:(FootsieTargetView*)from to:(FootsieTargetView*)to;

@end

static NSURL *_resource_url(NSString *name, NSString *type)
{
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:name ofType:type]];
}

static BOOL _too_close(FootsieTargetView *a, FootsieTargetView *b)
{
    CGPoint distance = CGPointMake(a.center.x-b.center.x, a.center.y-b.center.y);

    return distance.x*distance.x + distance.y*distance.y <= 100.0*100.0 + 95.0*95.0 + 1.0;
}

@implementation FootsieView

@synthesize targets;

- (FootsiePulseView*)_pulseFromView:(UIView*)view color:(UIColor*)color direction:(FootsiePulseViewDirection)direction
{
    FootsiePulseView *pulse = [[FootsiePulseView alloc]
        initWithCenter:CGPointMake(CGRectGetMidX(view.frame), CGRectGetMidY(view.frame))
        color:color
        direction:direction
    ];

    [self addSubview:pulse];
    [self sendSubviewToBack:pulse];
    
    return [pulse autorelease];
}

- (void)_pulseTimerTick:(NSTimer*)timer
{
    if (isCelebrating)
        return;

    NSMutableArray *pulses = [[NSMutableArray alloc] init];

    if (toGoal) {
        if (fromGoal)
            if (fromGoal.isOn)
                [pulses addObject:[self _pulseFromView:fromGoal color:fromGoal.color direction:PulseOut]];
            else
                fromGoal = nil;
        [pulses addObject:[self _pulseFromView:toGoal color:[UIColor redColor] direction:PulseIn]];
    } else {
        for (FootsieTargetView *goal in goalTargets)
            [pulses addObject:[self _pulseFromView:goal
                color:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4]
                direction:PulseIn
            ]];
    }

    [UIView beginAnimations:nil context:pulses];

    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_pulseAnimationDidStop:finished:context:)];
    for (FootsiePulseView *pulse in pulses)
        [pulse pulseAnimation];

    [UIView commitAnimations];
}

- (void)_pulseAnimationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context
{
    NSArray *pulses = (NSArray*)context;

    for (UIView *pulse in pulses) {
        [pulse removeFromSuperview];
    }
    [pulses release];
}

- (void)_splashViewFadeOutDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context
{
    [splashView release];
}

- (void)addGoal:(FootsieTargetView*)t
{
    t.isGoal = YES;
    [goalTargets addObject:t];
}

- (void)removeGoal:(FootsieTargetView*)t
{
    t.isGoal = NO;
    [goalTargets removeObject:t];
}

- (UIColor*)_backgroundColor
{
    return [UIColor blackColor];
}

- (void)moveGoal:(FootsieTargetView*)from to:(FootsieTargetView*)to
{
    [self removeGoal:from];
    [self addGoal:to];
    fromGoal = from; toGoal = to;
}

- (void)awakeFromNib
{
    NSMutableArray *targets_tmp = [NSMutableArray array];
    goalTargets = [[NSMutableSet alloc] init];

    for (UIView *subview in [self subviews])
        if ([subview isKindOfClass:[FootsieTargetView class]]) {
            [targets_tmp addObject:subview]; 
            if (subview.tag == 1)
                [self addGoal:(FootsieTargetView*)subview];
        }
    targets = [[NSArray alloc] initWithArray:targets_tmp];
    fromGoal = toGoal = nil;
    isCelebrating = NO;

    pulseTimer = [[NSTimer
        scheduledTimerWithTimeInterval:0.4
        target:self
        selector:@selector(_pulseTimerTick:)
        userInfo:nil
        repeats:YES
    ] retain];

    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Boot", @"wav"), &bootSound);
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Goal", @"aiff"), &goalSound);

    [UIView beginAnimations:nil context:nil];

    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_splashViewFadeOutDidStop:finished:context:)];

    splashView.alpha = 0.0;

    [UIView commitAnimations];
}

- (void)dealloc
{
    AudioServicesDisposeSystemSoundID(bootSound);
    AudioServicesDisposeSystemSoundID(goalSound);

    [pulseTimer invalidate];
    [pulseTimer release];
    [targets release];
    [goalTargets release];
    [super dealloc];
}

- (void)_updateForTouches:(NSSet*)touches
{
    if (isCelebrating)
        return;

    if ([self _goalsReached])
        [self _celebrateGoalsReached];

    for (FootsieTargetView *target in targets) {
        BOOL isOn = NO;
        for (UITouch *touch in touches) {
            if ([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled)
                continue;
            if (CGRectContainsPoint([target touchRegion], [touch locationInView:self]))
                isOn = YES;
        }
        target.isOn = isOn;
    }
}

- (BOOL)_goalsReached
{
    for (FootsieTargetView *target in goalTargets) {
        if (!target.isOn)
            return NO;
    }
    return YES;
}

- (void)_celebrateGoalsReached
{
    isCelebrating = YES;

    UIColor *oldColor = [self.backgroundColor retain];
    self.backgroundColor = [UIColor whiteColor];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.backgroundColor = oldColor;
    [UIView commitAnimations];

    if (!toGoal)
        AudioServicesPlaySystemSound(bootSound);
    AudioServicesPlaySystemSound(goalSound);

    [[NSTimer
        scheduledTimerWithTimeInterval:0.5
        target:self
        selector:@selector(_moveRandomGoalAfterDelay:)
        userInfo:nil
        repeats:NO
    ] retain];

    [oldColor release];
}

- (void)_moveRandomGoalAfterDelay:(NSTimer*)timer
{
    FootsieTargetView *from, *to;
    do { from = [goalTargets randomObject]; } while (from == toGoal);
    do { to   = [targets randomObject];     } while (to.isGoal || _too_close(from, to));
    [self moveGoal:from to:to];

    [timer invalidate];
    [timer release];
    isCelebrating = NO;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self _updateForTouches:[event allTouches]];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self _updateForTouches:[event allTouches]];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self _updateForTouches:[event allTouches]];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self _updateForTouches:[event allTouches]];
}

@end
