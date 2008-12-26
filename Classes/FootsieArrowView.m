#import "FootsieArrowView.h"
#import "FootsieTargetView.h"

static const CGFloat LINE_WIDTH = 10.0;

static inline CGFloat fmin3(CGFloat a, CGFloat b, CGFloat c) { return fmin(fmin(a,b),c); }
static inline CGFloat fmax3(CGFloat a, CGFloat b, CGFloat c) { return fmax(fmax(a,b),c); }

static CGFloat _factor(CGPoint pt, CGPoint distance, NSSet *targets)
{
    CGFloat length = 50.0 / sqrt(distance.x*distance.x + distance.y*distance.y);
    CGAffineTransform inv = CGAffineTransformMake(distance.x, distance.y, distance.y, -distance.x, pt.x, pt.y);
    CGAffineTransform t = CGAffineTransformInvert(inv);

    CGFloat f = 0.5;

    for (FootsieTargetView *v in targets) {
        CGPoint p = CGPointApplyAffineTransform(v.center, t);
        if (p.x < 0.05 || p.x > 0.95)
            continue;
        CGFloat x = p.x > 0.5 ? 1.0 - p.x : p.x;
        CGFloat ymin = fabs(p.y - length)/x, ymax = fabs(p.y + length)/x;
        if (f > ymin && f < ymax)
            f = f - ymin < ymax - f ? ymin : ymax;
    }
    NSLog(@"%f", f);
    return f;
}

@implementation FootsieArrowView

- (id)initFromPoint:(CGPoint)f toPoint:(CGPoint)t aroundTargets:(NSSet*)targets
{
    if (self = [super init]) {
        CGPoint distance = CGPointMake(t.x - f.x, t.y - f.y);
        CGFloat factor = _factor(f, distance, targets);
        CGPoint controlPoint = CGPointMake(f.x + 0.5*distance.x + factor*distance.y, f.y + 0.5*distance.y - factor*distance.x);

        CGPoint corner = CGPointMake(fmin3(f.x, t.x, controlPoint.x), fmin3(f.y, t.y, controlPoint.y));
        CGPoint extent = CGPointMake(fmax3(f.x, t.x, controlPoint.x), fmax3(f.y, t.y, controlPoint.y));

        CGRect frame = CGRectMake(corner.x, corner.y, extent.x-corner.x, extent.y-corner.y);
        frame = CGRectInset(frame, -LINE_WIDTH, -LINE_WIDTH);

        self.frame = frame;
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];

        from = CGPointMake(f.x - corner.x + LINE_WIDTH, f.y - corner.y + LINE_WIDTH);
        control = CGPointMake(controlPoint.x - corner.x + LINE_WIDTH, controlPoint.y - corner.y + LINE_WIDTH);
        to   = CGPointMake(t.x - corner.x + LINE_WIDTH, t.y - corner.y + LINE_WIDTH);
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    static const CGFloat lineDash[] = { 10.0, 20.0 };

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineDash(context, 10.0, lineDash, 2);

    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddQuadCurveToPoint(context, control.x, control.y, to.x, to.y);
    CGContextStrokePath(context);

    CGContextRestoreGState(context);
}

@end
