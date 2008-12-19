#import "FootsieView.h"
#import "FootsiePulseView.h"
#import "FootsieGameOverView.h"
#import "FootsiePausedView.h"
#import "misc.h"
#include <stdlib.h>
#include <math.h>

@interface FootsieView ()

- (NSSet*)_goalTargets;

- (void)_updateForTouches:(NSSet*)touches;
- (BOOL)_goalsReached;
- (void)_celebrateGoalsReached;
- (void)_moveRandomGoalAfterDelay:(NSTimer*)t;
- (void)_moveRandomGoalInSet:(NSMutableSet*)set;
- (void)_moveOneRandomGoal;
- (void)_moveTwoRandomGoals;
- (UIColor*)_backgroundColor;
- (NSMutableArray*)_pulseGoals:(NSSet*)set withColor:(UIColor*)color;

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

- (void)addGoal:(FootsieTargetView*)t toSet:(NSMutableSet*)set;
- (void)removeGoal:(FootsieTargetView*)t fromSet:(NSMutableSet*)set;
- (void)moveGoal:(FootsieTargetView*)from to:(FootsieTargetView*)to inSet:(NSMutableSet*)set;

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

- (NSSet*)_goalTargets
{
    return [p1GoalTargets setByAddingObjectsFromSet:p2GoalTargets];
}

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

- (NSMutableArray*)_pulseGoals:(NSSet*)set withColor:(UIColor*)color
{
    NSMutableArray *pulses = [NSMutableArray array];

    for (FootsieTargetView *goal in set) {
        if (isPaused)
            [pulses addObject:[self _pulseFromView:goal color:color direction:PulseIn]];
        else {
            if (!goal.isOn) {
                if (![toGoals containsObject:goal]) {
                    ++goal.deathPulses;
                    if (!isEnded && [goal isDead])
                        [self _endGame:goal];
                }
                [pulses addObject:[self _pulseFromView:goal color:color direction:PulseIn]];
            }
        }
    }
    return pulses;
}

- (void)_pulseTimerTick:(NSTimer*)timer
{
    if (isCelebrating || isEnded)
        return;

    NSMutableArray *pulses = [[NSMutableArray alloc] init];

    for (FootsieTargetView *fromGoal in [fromGoals allObjects]) {
        if (fromGoal.isOn)
            [pulses addObject:[self _pulseFromView:fromGoal color:fromGoal.color direction:PulseOut]];
        else
            [fromGoals removeObject:fromGoal];
    }

    [pulses addObjectsFromArray:[self _pulseGoals:p1GoalTargets withColor:
        [UIColor colorWithRed:1.0 green:0.2 blue:0.4 alpha:0.80]
    ]];
    [pulses addObjectsFromArray:[self _pulseGoals:p2GoalTargets withColor:
        [UIColor colorWithRed:1.0 green:0.4 blue:0.2 alpha:0.80]
    ]];

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

- (void)addGoal:(FootsieTargetView*)t toSet:(NSMutableSet*)set
{
    t.isGoal = YES;
    [set addObject:t];
}

- (void)removeGoal:(FootsieTargetView*)t fromSet:(NSMutableSet*)set
{
    t.isGoal = NO;
    [set removeObject:t];
}

- (UIColor*)_backgroundColor
{
    return [UIColor blackColor];
}

- (void)moveGoal:(FootsieTargetView*)from to:(FootsieTargetView*)to inSet:(NSMutableSet*)set
{
    [self removeGoal:from fromSet:set];
    [self addGoal:to toSet:set];
    [fromGoals addObject:from]; [toGoals addObject:to];
}

- (void)awakeFromNib
{
    NSMutableArray *targets_tmp = [NSMutableArray array];
    p1GoalTargets = [[NSMutableSet alloc] init];
    p2GoalTargets = [[NSMutableSet alloc] init];

    for (UIView *subview in [self subviews])
        if ([subview isKindOfClass:[FootsieTargetView class]])
            [targets_tmp addObject:subview]; 
    targets = [[NSArray alloc] initWithArray:targets_tmp];

    fromGoals = [[NSMutableSet alloc] init];
    toGoals   = [[NSMutableSet alloc] init];
    isCelebrating = NO;
    isP1 = !(rand() % 0x40000000);

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
    pauseView = [[FootsiePausedView alloc] init];
    //XXX startView = [[FootsieIntroView alloc] init];

    [self _resetGame];
    [self _dropInInfoView:startView];
}

- (void)_resetGame
{
    [p1GoalTargets removeAllObjects];
    [p2GoalTargets removeAllObjects];
    isPaused = YES;
    isEnded = NO;
    [fromGoals removeAllObjects];
    [toGoals removeAllObjects];
    score = 0;
    for (FootsieTargetView *target in targets) {
        [target reset];
        if (target.tag == 1)
            [self addGoal:(FootsieTargetView*)target toSet:p1GoalTargets];
        if (target.tag == 2)
            [self addGoal:(FootsieTargetView*)target toSet:p2GoalTargets];
    }
    [self _dropOutInfoView];
}

- (void)_pauseGame
{
    if (isPaused)
        return;

    isPaused = YES;
    isEnded = NO;
    [fromGoals removeAllObjects];
    [toGoals removeAllObjects];
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
    [p1GoalTargets release];
    [p2GoalTargets release];
    [fromGoals release];
    [toGoals release];
    [endView release];
    [pauseView release];
    [startView release];
    [super dealloc];
}

- (void)_updateForTouches:(NSSet*)touches
{
    if (isEnded)
        return;

    if ([touches count] > 4) {
        [self _pauseGame];
        return;
    }

    if (!isCelebrating && [self _goalsReached])
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
    for (FootsieTargetView *target in [self _goalTargets]) {
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

    if ([toGoals count] == 0)
        AudioServicesPlaySystemSound(bootSound);
    AudioServicesPlaySystemSound(goalSound);

    [toGoals removeAllObjects];

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
    if (_rand_between(0.0, 1.0) < 0.1)
        [self _moveTwoRandomGoals];
    else
        [self _moveOneRandomGoal];

    [timer invalidate];
    [timer release];
    isCelebrating = NO;
}

- (void)_moveRandomGoalInSet:(NSMutableSet*)set
{
    FootsieTargetView *from, *to;
    do { from = [set randomObject]; } while ([toGoals containsObject:from]);
    do { to   = [targets randomObject]; } while (to.isGoal || _too_close(from, to));
    [self moveGoal:from to:to inSet:set];
}

- (void)_moveOneRandomGoal
{
    NSMutableSet *set = (isP1 = !isP1) ? p1GoalTargets : p2GoalTargets;
    [self _moveRandomGoalInSet:set];
}

- (void)_moveTwoRandomGoals
{
    [self _moveRandomGoalInSet:p1GoalTargets];
    [self _moveRandomGoalInSet:p2GoalTargets];
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
