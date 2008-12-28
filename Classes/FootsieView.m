#import "FootsieView.h"
#import "FootsieArrowView.h"
#import "FootsiePulseView.h"
#import "FootsieGameOverView.h"
#import "FootsieIntroView.h"
#import "FootsieFlowerView.h"
#import "misc.h"
#include <stdlib.h>
#include <math.h>

static enum FootsieArrowMode {
    ArrowsNever = 0,
    ArrowsTandemOnly = 1,
    ArrowsAlways = 2
} ARROW_MODE;

@interface FootsieView ()

- (NSSet*)_goalTargets;

- (void)_updateForTouches:(NSSet*)touches;
- (BOOL)_goalsReached;
- (void)_celebrateGoalsReached;
- (void)_moveRandomGoalAfterDelay:(NSTimer*)t;
- (void)_moveRandomGoalInSet:(NSMutableSet*)set withArrow:(BOOL)arrow;
- (void)_moveOneRandomGoal;
- (void)_moveTwoRandomGoals;
- (UIColor*)_backgroundColor;
- (NSMutableArray*)_pulseGoals:(NSSet*)set withColor:(UIColor*)color alarm:(BOOL*)alarm;

- (FootsiePulseView*)_pulseFromView:(UIView*)view color:(UIColor*)color direction:(FootsiePulseViewDirection)direction;

- (void)_killSubviewsOfClass:(Class)clas;
- (void)_flashBackground:(UIColor*)color;
- (void)_addFlower;

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

static BOOL _too_close(FootsieTargetView *a, FootsieTargetView *b)
{
    CGPoint distance = CGPointMake(a.center.x-b.center.x, a.center.y-b.center.y);

    return distance.x*distance.x + distance.y*distance.y <= 100.0*100.0 + 95.0*95.0 + 1.0;
}

@implementation FootsieView

@synthesize targets, score;
@synthesize bootSound, goalSound, endSound, coinSound, cashSound;

+ (void)initialize
{
    ARROW_MODE = [[[NSUserDefaults standardUserDefaults] stringForKey:@"arrows"] intValue];
}

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

- (NSMutableArray*)_pulseGoals:(NSSet*)set withColor:(UIColor*)color alarm:(BOOL*)alarm
{
    NSMutableArray *pulses = [NSMutableArray array];

    for (FootsieTargetView *goal in set) {
        if (isPaused)
            [pulses addObject:[self _pulseFromView:goal color:color direction:PulseIn]];
        else {
            if (!goal.isOn) {
                if (![toGoals containsObject:goal]) {
                    *alarm = YES;
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
    BOOL alarm = NO;

    if (isCelebrating || isEnded)
        return;

    NSMutableArray *pulses = [[NSMutableArray alloc] init];

    for (FootsieTargetView *fromGoal in [fromGoals allObjects]) {
        //if (fromGoal.isOn)
            [pulses addObject:[self _pulseFromView:fromGoal color:_with_alpha(fromGoal.color, 0.7) direction:PulseOut]];
        //else
        //    [fromGoals removeObject:fromGoal];
    }

    [pulses addObjectsFromArray:[self
        _pulseGoals:p1GoalTargets
        withColor:[UIColor colorWithRed:1.0 green:0.2 blue:0.5 alpha:0.70]
        alarm:&alarm
    ]];
    [pulses addObjectsFromArray:[self
        _pulseGoals:p2GoalTargets
        withColor:[UIColor colorWithRed:1.0 green:0.5 blue:0.2 alpha:0.70]
        alarm:&alarm
    ]];

    if (alarm && !isEnded)
        AudioServicesPlaySystemSound(alarmSound);

    [UIView beginAnimations:nil context:pulses];

    [UIView setAnimationDuration:1.0];
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
    //[self _dropInInfoView:startView];
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
    isP1 = !(rand() & 0x40000000);

    pulseTimer = [[NSTimer
        scheduledTimerWithTimeInterval:0.5
        target:self
        selector:@selector(_pulseTimerTick:)
        userInfo:nil
        repeats:YES
    ] retain];

    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Boot", @"aiff"), &bootSound);
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Goal", @"aiff"), &goalSound);
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Crash", @"aiff"), &endSound);
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Cash", @"aiff"), &cashSound);
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Coin", @"aiff"), &coinSound);
    AudioServicesCreateSystemSoundID((CFURLRef)_resource_url(@"Alarm", @"aiff"), &alarmSound);

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_splashViewFadeOutDidStop:finished:context:)];
    splashView.alpha = 0.0;
    [UIView commitAnimations];

    endView = [[FootsieGameOverView alloc] init];
    pauseView = [[FootsieIntroView alloc] initWithBackground:@"Paused" instructions:NO];
    startView = [[FootsieIntroView alloc] initWithBackground:@"Intro"  instructions:YES];

    [self _resetGame];

    activeInfoView = startView;
    startView.center = self.center;
    startView.transform = CGAffineTransformMake(0.0, -1.0, 1.0, 0.0, 0.0, 0.0);
    [self addSubview:startView];
}

- (void)_resetGame
{
    [self _killSubviewsOfClass:[FootsieFlowerView class]];
    [p1GoalTargets removeAllObjects];
    [p2GoalTargets removeAllObjects];
    isPaused = YES;
    isEnded = NO;
    [fromGoals removeAllObjects];
    [toGoals removeAllObjects];
    score = 0;
    turnScoreValue = 1;
    turnsUntilTandem = _rand_between(8, 13);
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
    if (isPaused || isEnded)
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
    AudioServicesDisposeSystemSoundID(cashSound);
    AudioServicesDisposeSystemSoundID(coinSound);
    AudioServicesDisposeSystemSoundID(alarmSound);

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

    NSMutableSet *firstFourTouches = [NSMutableSet setWithSet:touches];
    while ([firstFourTouches count] > 4)
        [firstFourTouches removeObject:[firstFourTouches anyObject]];

    for (FootsieTargetView *target in targets) {
        BOOL isOn = NO;
        for (UITouch *touch in [firstFourTouches allObjects]) {
            if ([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled)
                continue;
            if (CGRectContainsPoint([target touchRegion], [touch locationInView:self])) {
                [firstFourTouches removeObject:touch];
                isOn = YES;
            }
        }
        target.isOn = isOn;
    }

    if (!isCelebrating && [self _goalsReached])
        [self _celebrateGoalsReached];
}

- (BOOL)_goalsReached
{
    for (FootsieTargetView *target in [self _goalTargets]) {
        if (!target.isOn)
            return NO;
    }
    return YES;
}

- (void)_killSubviewsOfClass:(Class)clas
{
    for (UIView *view in [self subviews])
        if ([view isKindOfClass:clas])
            [view removeFromSuperview];
}

- (void)_flashBackground:(UIColor*)color
{
    UIColor *oldColor = [self.backgroundColor retain];
    self.backgroundColor = color;

    [self _killSubviewsOfClass:[FootsiePulseView class]];
    [self _killSubviewsOfClass:[FootsieArrowView class]];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.backgroundColor = oldColor;
    [UIView commitAnimations];

    [oldColor release];
}

- (void)_addFlower
{
    CGPoint flowerCenter = [[targets randomObject] center];
    CGFloat rho = _rand_between(38.0, 40.0), theta = _rand_between(0.0, 2*M_PI);

    FootsieFlowerView *flower = [[[FootsieFlowerView alloc]
        initAtPoint:CGPointMake(flowerCenter.x + rho*cos(theta), flowerCenter.y + rho*sin(theta))
        forScore:score
    ] autorelease];
    flower.transform = CGAffineTransformMakeScale(0.01, 0.01);

    [self addSubview:flower];
    if (rand() & 0x40000000) [self sendSubviewToBack:flower];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    flower.transform = CGAffineTransformMakeScale(1.0, 1.0);
    [UIView commitAnimations];
}

- (void)_celebrateGoalsReached
{
    isCelebrating = YES;
    if (isPaused)
        isPaused = NO;
    else for (unsigned i = 0; i < turnScoreValue; ++i) {
        [self _addFlower];
        ++score;
    }

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
    [fromGoals removeAllObjects];
    if (--turnsUntilTandem == 0) {
        turnsUntilTandem = _rand_between(8, 13);
        [self _moveTwoRandomGoals];
    } else
        [self _moveOneRandomGoal];

    [timer invalidate];
    [timer release];
    isCelebrating = NO;
}

- (void)_moveRandomGoalInSet:(NSMutableSet*)set withArrow:(BOOL)arrow
{
    FootsieTargetView *from, *to;
    do { from = [set randomObject]; } while ([toGoals containsObject:from]);
    do { to   = [targets randomObject]; } while ([fromGoals containsObject:to] || to.isGoal || _too_close(from, to));
    [self moveGoal:from to:to inSet:set];

    if (arrow)
        [self addSubview:[[[FootsieArrowView alloc]
            initFromPoint:from.center toPoint:to.center aroundTargets:[self _goalTargets]
        ] autorelease]];
}

- (void)_moveOneRandomGoal
{
    turnScoreValue = 1;

    NSMutableSet *set = (isP1 = !isP1) ? p1GoalTargets : p2GoalTargets;
    [self _moveRandomGoalInSet:set withArrow:(ARROW_MODE >= ArrowsAlways)];
}

- (void)_moveTwoRandomGoals
{
    turnScoreValue = 3;

    [self _moveRandomGoalInSet:p1GoalTargets withArrow:(ARROW_MODE >= ArrowsTandemOnly)];
    [self _moveRandomGoalInSet:p2GoalTargets withArrow:(ARROW_MODE >= ArrowsTandemOnly)];
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
