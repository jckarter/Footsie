#import "FootsiePulseView.h"

static const CGFloat PULSE_NATIVE_RADIUS = 40.0;
static const CGFloat PULSE_NATIVE_STROKE_WIDTH = 8.0;

static CGAffineTransform _in_transform, _out_transform;

static void _pulse_out(UIView *v) { v.transform = _out_transform; v.alpha = 0.0; }
static void _pulse_in(UIView *v)  { v.transform = _in_transform;  v.alpha = 1.0; }

@implementation FootsiePulseView

@synthesize color;

+ (void)initialize
{
    _in_transform = CGAffineTransformMakeScale(0.5, 0.5);
    _out_transform = CGAffineTransformMakeScale(5.0, 5.0);
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

    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, PULSE_NATIVE_STROKE_WIDTH);
    CGContextStrokeEllipseInRect(context,
        CGRectInset(self.bounds, PULSE_NATIVE_STROKE_WIDTH*0.5, PULSE_NATIVE_STROKE_WIDTH*0.5)
    );
}

@end
