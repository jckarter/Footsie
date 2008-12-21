#import "FootsiePulseView.h"

static const CGFloat PULSE_NATIVE_RADIUS = 20.0;
static const CGFloat PULSE_NATIVE_STROKE_WIDTH = 3.0;
static const unsigned PULSE_SLICES = 11;

static CGAffineTransform _in_transform, _out_transform;

static void _pulse_out(UIView *v) { v.transform = _out_transform; v.alpha = 0.0; }
static void _pulse_in(UIView *v)  { v.transform = _in_transform;  v.alpha = 1.0; }

@implementation FootsiePulseView

@synthesize color;

+ (void)initialize
{
    _in_transform = CGAffineTransformMakeScale(1.0, 1.0);
    _out_transform = CGAffineTransformMakeScale(10.0, 10.0);
}

- (FootsiePulseView*)initWithCenter:(CGPoint)point color:(UIColor*)co direction:(FootsiePulseViewDirection)dir
{
    if (self = [super init]) {
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        self.frame = CGRectMake(
            0, 0,
            PULSE_NATIVE_RADIUS*2, PULSE_NATIVE_RADIUS*2
        );
        self.center = point;
        self.color = co;

        if (dir == PulseOut) {
            _pulse_in(self);
        } else {
            _pulse_out(self);
        }

        direction = dir;
    }
    return self;
}

- (void)pulseAnimation
{
    if (direction == PulseOut) {
        _pulse_out(self);
    } else {
        _pulse_in(self);
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

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    CGFloat front, back;
    if (direction == PulseOut) {
        back = PULSE_NATIVE_RADIUS-PULSE_NATIVE_STROKE_WIDTH;
        front = PULSE_NATIVE_RADIUS;
    } else {
        front = PULSE_NATIVE_RADIUS-PULSE_NATIVE_STROKE_WIDTH;
        back = PULSE_NATIVE_RADIUS;
    }

    for (unsigned i = 0; i < PULSE_SLICES; ++i) {
        CGContextSaveGState(context);
        CGContextRotateCTM(context, i * 2*M_PI / PULSE_SLICES);
        CGContextMoveToPoint(context, front, 0.0);
        CGContextAddLineToPoint(context, back,  PULSE_NATIVE_STROKE_WIDTH);
        CGContextAddLineToPoint(context, back, -PULSE_NATIVE_STROKE_WIDTH);
        CGContextClosePath(context);
        CGContextFillPath(context);
        CGContextRestoreGState(context);
    }
}

@end
