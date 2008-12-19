#import "FootsieView.h"
#import "FootsiePulseView.h"
#import "FootsieGameOverView.h"
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

- (void)_flashBackground:(UIColor*)color;

- (void)_pulseTimerTick:(NSTimer*)timer;
- (void)_pulseAnimationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context;

- (void)_splashViewFadeOutDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context;
- (void)_dropOutInfoViewDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context;

- (void)_pauseGame;
- (void)_resetGame;
- (void)_endGame:(FootsieTargetView*)source;

- (void)_dropInInfoView:(UIView*)view;
- (void)_dropOutInfoView;

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

@synthesize targets, score;

- (NSString*)scoreString
{
    return [NSString stringWithFormat:@"Your score: %u", score];
}

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

- (void)_dropInInfoView:(UIView*)view
{
    if (activeInfoView)
        [self _dropOutInfoView];

    view.center = self.center;
    view.transform = CGAffineTransformMake(0.0, -0.01, 0.01, 0.0, 0.0, 0.0);
    view.alpha = 0.0;
    [self addSubview:view];

    [UIView beginAnimations:nil context:nil];
    view.transform = CGAffineTransformMake(0.0, -1.0, 1.0, 0.0, 0.0, 0.0);
    view.alpha = 1.0;
    [UIView commitAnimations];

    activeInfoView = view;
}

- (void)_dropOutInfoView
{
    if (!activeInfoView)
        return;

    [UIView beginAnimations:nil context:activeInfoView];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_dropOutInfoViewDidStop:finished:context:)];
    activeInfoView.transform = CGAffineTransformMake(0.0, -3.0, 3.0, 0.0, 0.0, 0.0);
    activeInfoView.alpha = 0.0;
    [UIView commitAnimations];

    activeInfoView = nil;
}

- (void)_dropOutInfoViewDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context
{
    UIView *view = (UIView*)context;
    [view removeFromSuperview];
}

- (void)_pulseTimerTick:(NSTimer*)timer
{
    if (isCelebrating || isEnded)
        return;

    NSMutableArray *pulses = [[NSMutableArray alloc] init];

    if (fromGoal) {
        if (fromGoal.isOn)
            [pulses addObject:[self _pulseFromView:fromGoal color:fromGoal.color direction:PulseOut]];
        else
            fromGoal = nil;
    }

    for (FootsieTargetView *goal in goalTargets) {
        if (isPaused)
            [pulses addObject:[self _pulseFromView:goal
                color:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2]
                direction:PulseIn
            ]];
        else {
            if (!goal.isOn) {
                if (goal != toGoal) {
                    ++goal.deathPulses;
                    if ([goal isDead]) {
                        [self _endGame:goal];
                        return;
                    }
                }
                [pulses addObject:[self _pulseFromView:goal
                    color:[UIColor redColor]
                    direction:PulseIn
                ]];
            }
        }
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
        if ([subview isKindOfClass:[FootsieTargetView class]])
            [targets_tmp addObject:subview]; 
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
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Crash", @"aiff"), &endSound);

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_splashViewFadeOutDidStop:finished:context:)];
    splashView.alpha = 0.0;
    [UIView commitAnimations];

    activeInfoView = nil;
    endView = [[FootsieGameOverView alloc] init];
    //XXX pauseView = [[FootsiePopupView alloc] initWithMessage:@"P A U S E D"];
    //XXX startView = [[FootsiePopupView alloc] initWithMessage:@"F O O T S I E"];

    [self _resetGame];
}

- (void)_resetGame
{
    [goalTargets removeAllObjects];
    isPaused = YES;
    isEnded = NO;
    fromGoal = toGoal = nil;
    score = 0;
    for (FootsieTargetView *target in targets) {
        [target reset];
        if (target.tag == 1)
            [self addGoal:(FootsieTargetView*)target];
    }
    [self _dropOutInfoView];
    //XXX [self _dropInInfoView:startView];
}

- (void)_pauseGame
{
    isPaused = YES;
    isEnded = NO;
    fromGoal = toGoal = nil;
    for (FootsieTargetView *target in targets)
        target.isOn = NO;
    [self _dropInInfoView:pauseView];
}

- (void)_endGame:(FootsieTargetView*)sourceTarget
{
    AudioServicesPlayAlertSound(endSound);

    isEnded = YES;

    [self _flashBackground:[UIColor redColor]];
    for (FootsieTargetView *target in targets) {
        target.isOn = (target == sourceTarget);
        target.deathPulses = 1000;
    }
    endView.score = score;
    [self _dropInInfoView:endView];
}

- (void)dealloc
{
    AudioServicesDisposeSystemSoundID(bootSound);
    AudioServicesDisposeSystemSoundID(goalSound);
    AudioServicesDisposeSystemSoundID(endSound);

    [pulseTimer invalidate];
    [pulseTimer release];
    [targets release];
    [goalTargets release];
    [endView release];
    [pauseView release];
    [startView release];
    [super dealloc];
}

- (void)_updateForTouches:(NSSet*)touches
{
    if (isCelebrating || isEnded)
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

- (void)_flashBackground:(UIColor*)color
{
    UIColor *oldColor = [self.backgroundColor retain];
    self.backgroundColor = color;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.backgroundColor = oldColor;
    [UIView commitAnimations];

    [oldColor release];
}

- (void)_celebrateGoalsReached
{
    isCelebrating = YES;
    if (isPaused)
        isPaused = NO;
    else
        ++score;

    [self _dropOutInfoView];
    [self _flashBackground:[UIColor whiteColor]];

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
    [self _pauseGame];
}

@end
