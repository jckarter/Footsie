#import "FootsieArrowView.h"

static const CGFloat LINE_WIDTH = 10.0;

@implementation FootsieArrowView

- (id)initFromPoint:(CGPoint)f toPoint:(CGPoint)t
{
    if (self = [super init]) {
        CGPoint corner = CGPointMake(fmin(f.x, t.x), fmin(f.y, t.y));
        CGPoint extent = CGPointMake(fmax(f.x, t.x), fmax(f.y, t.y));

        CGRect frame = CGRectMake(corner.x, corner.y, extent.x-corner.x, extent.y-corner.y);
        frame = CGRectInset(frame, -LINE_WIDTH, -LINE_WIDTH);

        self.frame = frame;

        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];

        from = CGPointMake(f.x - corner.x + LINE_WIDTH, f.y - corner.y + LINE_WIDTH);
        to   = CGPointMake(t.x - corner.x + LINE_WIDTH, t.y - corner.y + LINE_WIDTH);
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    static const CGFloat lineDash[] = { 0.0, 20.0 };

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineDash(context, 10.0, lineDash, 2);

    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, from.x, from.y);
    CGContextAddLineToPoint(context, to.x, to.y);
    CGContextStrokePath(context);

    CGContextRestoreGState(context);
}

@end
