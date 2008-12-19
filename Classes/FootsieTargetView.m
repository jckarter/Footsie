#import "FootsieTargetView.h"
#import "misc.h"

static NSArray *targetColors;
static const unsigned DEATH_PULSES = 2;

static void _happy_face(CGContextRef context)
{
    CGFloat leftEyeRadius  = _rand_between(7.0, 9.0);
    CGFloat rightEyeRadius = _rand_between(7.0, 9.0);

    CGContextBeginPath(context);
    CGContextAddArc(context, -17.0 - leftEyeRadius,  0.0, leftEyeRadius, M_PI, 2*M_PI, 0);
    CGContextMoveToPoint(context, 17.0, 0.0);
    CGContextAddArc(context,  17.0 + rightEyeRadius, 0.0, rightEyeRadius, M_PI, 2*M_PI, 0);

    CGContextMoveToPoint   (context, -34.0, -5.0 - leftEyeRadius);
    CGContextAddLineToPoint(context, -28.0, -7.0 - leftEyeRadius);
    CGContextMoveToPoint   (context,  34.0, -5.0 - rightEyeRadius);
    CGContextAddLineToPoint(context,  28.0, -7.0 - rightEyeRadius);
}

static void _asleep_face(CGContextRef context)
{
    CGContextBeginPath(context);
    CGContextAddArc(context, -28.0, _epsilon(0.0, 1.0), 7.0, 0.25*M_PI, 0.75*M_PI, 0);
    CGContextMoveToPoint(context, 28.0 + 7.0*0.7071, 0.0 + 7.0*0.7071);
    CGContextAddArc(context,  28.0, _epsilon(0.0, 1.0), 7.0, 0.25*M_PI, 0.75*M_PI, 0);
}

static void _angry_face(CGContextRef context)
{
    CGContextBeginPath(context);
    CGContextMoveToPoint   (context, _epsilon(-15.0, 0.5), _epsilon(  5.0, 0.5));
    CGContextAddLineToPoint(context, _epsilon(-35.0, 2.0), _epsilon(-15.0, 2.0));
    CGContextMoveToPoint   (context, _epsilon( 15.0, 0.5), _epsilon(  5.0, 0.5));
    CGContextAddLineToPoint(context, _epsilon( 35.0, 2.0), _epsilon(-15.0, 2.0));

    CGFloat leftEyeRadius  = _rand_between(1.0, 5.0);
    CGFloat rightEyeRadius = _rand_between(1.0, 5.0);
    CGContextAddEllipseInRect(context, CGRectMake(-27.0-leftEyeRadius, -leftEyeRadius,  leftEyeRadius *2, leftEyeRadius *2));
    CGContextAddEllipseInRect(context, CGRectMake( 27.0,               -rightEyeRadius, rightEyeRadius*2, rightEyeRadius*2));
}

static void _dead_face(CGContextRef context)
{
    CGFloat leftEyeRadius  = _rand_between(7.0, 19.0);
    CGFloat rightEyeRadius = _rand_between(7.0, 19.0);
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(-39.0, -leftEyeRadius, leftEyeRadius*2, leftEyeRadius*2));
    CGContextAddEllipseInRect(context, CGRectMake( 39.0-rightEyeRadius*2, -rightEyeRadius, rightEyeRadius*2, rightEyeRadius*2));

    CGFloat leftEyeCenter  = _rand_between(-34.0, -39.0 + leftEyeRadius);
    CGFloat rightEyeCenter = _rand_between( 39.0 - rightEyeRadius, 34.0);

    CGContextMoveToPoint(context,    leftEyeCenter-2.0,  -2.0);
    CGContextAddLineToPoint(context, leftEyeCenter+2.0,   2.0);
    CGContextMoveToPoint(context,    leftEyeCenter-2.0,  2.0);
    CGContextAddLineToPoint(context, leftEyeCenter+2.0, -2.0);

    CGContextMoveToPoint(context,    rightEyeCenter+2.0, -2.0);
    CGContextAddLineToPoint(context, rightEyeCenter-2.0,  2.0);
    CGContextMoveToPoint(context,    rightEyeCenter+2.0,  2.0);
    CGContextAddLineToPoint(context, rightEyeCenter-2.0, -2.0);
}

static void _round_shape(CGContextRef context)
{
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, CGRectMake(-40, -40, 80, 80));
}

static FootsieShape _shapes[] = {
    _round_shape
};
static unsigned _num_shapes = sizeof(_shapes)/sizeof(_shapes[0]);

static inline FootsieSex _random_sex(void) { return rand() & 0x40000000 ? Female : Male; }
static inline FootsieShape _random_shape(void) { return _shapes[rand() % _num_shapes]; }

@interface FootsieTargetView ()

- (void)_startGoalTimer;
- (void)_stopGoalTimer;
- (void)_checkGoalTimer;
- (void)_goalTimerTick:(NSTimer*)timer;

@end

@implementation FootsieTargetView

@synthesize color, isOn, isGoal, deathPulses, shape, sex;

+ (void)initialize
{
    sranddev();
    targetColors = [[NSArray alloc] initWithObjects:
        _rgba(0xff, 0xd3, 0xc2, 0xff),
        _rgba(0xff, 0xac, 0x72, 0xff),
        _rgba(0xff, 0xd7, 0xaf, 0xff),
        _rgba(0xff, 0xf9, 0xdb, 0xff),
        nil
    ];
}

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder]) {
        self.color = [targetColors randomObject];
        isOn = NO; isGoal = NO;
        shape = _random_shape(); sex = _random_sex();
        redrawTimer = nil;
    }
    return self;
}

- (BOOL)isDead
{
    return deathPulses >= DEATH_PULSES;
}

- (void)setIsOn:(BOOL)x
{
    if (isOn != x) {
        isOn = x;
        deathPulses = 0;
        [self setNeedsDisplay];
        [self _checkGoalTimer];
    }
}

- (void)setIsGoal:(BOOL)x
{
    if (isGoal != x) {
        isGoal = x;
        [self setNeedsDisplay];
        [self _checkGoalTimer];
    }
}

- (void)setDeathPulses:(unsigned)x
{
    unsigned old = deathPulses;
    deathPulses = x;
    if ((old < DEATH_PULSES) ^ (deathPulses < DEATH_PULSES)) {
        [self setNeedsDisplay];
        [self _checkGoalTimer];
    }
}

- (void)reset
{
    isGoal = NO;
    isOn = NO;
    deathPulses = 0;
    [self setNeedsDisplay];
    [self _checkGoalTimer];
}

- (void)_goalTimerTick:(NSTimer*)timer
{
    [self setNeedsDisplay];
}

- (void)_checkGoalTimer
{
    if (!redrawTimer && deathPulses < DEATH_PULSES && isGoal && !isOn)
        [self _startGoalTimer];
    else if (redrawTimer)
        [self _stopGoalTimer];
}

- (void)_startGoalTimer
{
    redrawTimer = [[NSTimer
        scheduledTimerWithTimeInterval:0.1
        target:self
        selector:@selector(_goalTimerTick:)
        userInfo:nil
        repeats:YES
    ] retain];
}

- (void)_stopGoalTimer
{
    [redrawTimer invalidate];
    [redrawTimer release];
    redrawTimer = nil;
}

- (void)dealloc
{
    [redrawTimer invalidate];
    [redrawTimer release];
    [color release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGContextRotateCTM(context, -0.5*M_PI);

    if (isGoal && isOn) {
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(
            colorspace,
            (CFArrayRef)[NSArray arrayWithObjects:
                (id)_with_alpha(color, 1.0).CGColor,
                (id)_with_alpha(color, 0.0).CGColor,
                nil
            ],
            NULL
        );

        CGContextDrawRadialGradient(context, gradient,
            CGPointZero, 35.0, 
            CGPointZero, 50.0, 
            0 // kCGGradientDrawsBeforeStartLocation //| kCGGradientDrawsAfterEndLocation
        );
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorspace);
    }
    
    UIColor *c;
    FootsieFace face;
    if (deathPulses >= DEATH_PULSES) {
        c = _dead(color);
        face = _dead_face;
    } else if (isGoal && isOn) {
        c = _happy(color);
        face = _happy_face;
    } else if (isGoal && !isOn) {
        c = _angry(color);
        face = _angry_face;
    } else if (!isGoal && isOn) {
        c = _half_asleep(color);
        face = _asleep_face;
    } else {
        c = _asleep(color);
        face = _asleep_face;
    }

    CGContextSetFillColorWithColor(context, c.CGColor);
    shape(context);
    CGContextFillPath(context);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7].CGColor);
    CGContextSetLineWidth(context, 2.0);
    face(context);
    CGContextStrokePath(context);

    CGContextRestoreGState(context);
}

- (CGRect)touchRegion
{
    CGRect frame = self.frame;
    if (isGoal && isOn)
        return CGRectInset(frame, -5.0, -5.0);
    else
        return frame;
}

@end

