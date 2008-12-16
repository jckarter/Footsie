#import "FootsieTargetView.h"
#import "misc.h"

static NSArray *targetColors;

static void _happy_face(CGContextRef context)
{
    CGContextBeginPath(context);
    CGContextAddArc(context, -25.0, 0.0, 10.0, M_PI, 2*M_PI, 0);
    CGContextMoveToPoint(context, 15.0, 0.0);
    CGContextAddArc(context,  25.0, 0.0, 10.0, M_PI, 2*M_PI, 0);
}

static void _asleep_face(CGContextRef context)
{
    CGContextBeginPath(context);
    CGContextAddArc(context, -28.0, 0.0, 7.0, 0.25*M_PI, 0.75*M_PI, 0);
    CGContextMoveToPoint(context, 28.0 + 7.0*0.7071, 0.0 + 7.0*0.7071);
    CGContextAddArc(context,  28.0, 0.0, 7.0, 0.25*M_PI, 0.75*M_PI, 0);
}

static void _angry_face(CGContextRef context)
{
    CGContextBeginPath(context);
    CGContextMoveToPoint   (context, _epsilon(-15.0, 0.5), _epsilon(  5.0, 0.5));
    CGContextAddLineToPoint(context, _epsilon(-35.0, 2.0), _epsilon(-15.0, 2.0));
    CGContextMoveToPoint   (context, _epsilon( 15.0, 0.5), _epsilon(  5.0, 0.5));
    CGContextAddLineToPoint(context, _epsilon( 35.0, 2.0), _epsilon(-15.0, 2.0));

    CGFloat leftEyeRadius  = _rand_between(1.5, 3.0);
    CGFloat rightEyeRadius = _rand_between(1.5, 3.0);
    CGContextAddEllipseInRect(context, CGRectMake(-23.0-leftEyeRadius, -leftEyeRadius,  leftEyeRadius *2, leftEyeRadius *2));
    CGContextAddEllipseInRect(context, CGRectMake( 23.0,               -rightEyeRadius, rightEyeRadius*2, rightEyeRadius*2));
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

@implementation FootsieTargetView

@synthesize color, isOn, isGoal, shape, sex;

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
    }
    return self;
}

- (void)setIsOn:(BOOL)x
{
    if (isOn != x) {
        isOn = x;
        [self setNeedsDisplay];
    }
}

- (void)setIsGoal:(BOOL)x
{
    if (isGoal != x) {
        isGoal = x;
        [self setNeedsDisplay];
    }
}

- (void)dealloc
{
    [color release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

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
            CGPointZero, 30.0, 
            CGPointZero, 50.0, 
            0 // kCGGradientDrawsBeforeStartLocation //| kCGGradientDrawsAfterEndLocation
        );
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorspace);
    }
    
    UIColor *c;
    FootsieFace face;
    if (isGoal && isOn) {
        c = _happy(color);
        face = _happy_face;
    }
    else if (isGoal && !isOn) {
        c = _angry(color);
        face = _angry_face;
    }
    else if (!isGoal && isOn) {
        c = _half_asleep(color);
        face = _asleep_face;
    }
    else {
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

@end

