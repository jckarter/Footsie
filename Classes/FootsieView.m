#import "FootsieView.h"

FootsieColor
    FCRed    = { 1.0, 0.3, 0.3, 1.0 },
    FCGreen  = { 0.3, 1.0, 0.3, 1.0 },
    FCBlue   = { 0.5, 0.5, 1.0, 1.0 },
    FCYellow = { 1.0, 1.0, 0.2, 1.0 },
    FCOrange = { 1.0, 0.5, 0.3, 1.0 };

static inline CGFloat _bright(CGFloat f) { CGFloat ff = 1.0 - f; return 1.0 - (ff*ff); }

static void _log_touches(UIView *view, UIEvent *evt)
{
    NSMutableString *s = [NSMutableString string];
    for (UITouch *touch in [evt allTouches]) {
        [s appendString:[NSString stringWithFormat:@"<%p %d> ", touch, [touch phase]]];
    }

    NSLog(@"%@\n", s);
}

@interface FootsieView ()

- (void)_updateForTouches:(NSSet*)touches;

@end

@implementation FootsieTarget

@synthesize x, y, color, isOn;

- (FootsieTarget*)initWithX:(CGFloat)xx Y:(CGFloat)yy color:(FootsieColor*)cc
{
    if (self = [super init]) {
        x = xx; y = yy; color = cc;
        isOn = NO;
    }
    return self;
}

+ (FootsieTarget*)targetWithX:(CGFloat)x Y:(CGFloat)y color:(FootsieColor*)color
{
    return [[[FootsieTarget alloc] initWithX:x Y:y color:color] autorelease];
}

- (CGRect)rect
{
    return CGRectMake(x - 50, y - 50, 100, 100);
}

- (CGRect)innerRect
{
    return CGRectMake(x - 40, y - 40, 80, 80);
}

- (void)draw
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (isOn) {
        CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
        CGFloat colors[8] = {
            _bright(color->r), _bright(color->g), _bright(color->b), 0.75,
            color->r, color->g, color->b, 0.10
        };
        CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, 2);

        CGContextDrawRadialGradient(context, gradient,
            CGPointMake(x, y), 40.0, 
            CGPointMake(x, y), 50.0, 
            0 // kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation
        );
        CGGradientRelease(gradient);
        CFRelease(rgb);

        CGContextSetRGBFillColor(context, _bright(color->r), _bright(color->g), _bright(color->b), color->a * 0.8);
        CGContextFillEllipseInRect(context, [self innerRect]);
    } else {
        CGContextSetRGBFillColor(context, color->r, color->g, color->b, color->a);
        CGContextFillEllipseInRect(context, [self innerRect]);
    }
}

+ (NSArray*)rowsOfTargets
{
    return [NSArray arrayWithObjects:
        [FootsieTarget targetWithX: 60 Y: 50 color:&FCRed],
        [FootsieTarget targetWithX:160 Y: 50 color:&FCRed],
        [FootsieTarget targetWithX:260 Y: 50 color:&FCRed],

        [FootsieTarget targetWithX: 60 Y:145 color:&FCYellow],
        [FootsieTarget targetWithX:160 Y:145 color:&FCYellow],
        [FootsieTarget targetWithX:260 Y:145 color:&FCYellow],

        [FootsieTarget targetWithX: 60 Y:240 color:&FCBlue],
        [FootsieTarget targetWithX:160 Y:240 color:&FCBlue],
        [FootsieTarget targetWithX:260 Y:240 color:&FCBlue],

        [FootsieTarget targetWithX: 60 Y:335 color:&FCOrange],
        [FootsieTarget targetWithX:160 Y:335 color:&FCOrange],
        [FootsieTarget targetWithX:260 Y:335 color:&FCOrange],

        [FootsieTarget targetWithX: 60 Y:430 color:&FCGreen],
        [FootsieTarget targetWithX:160 Y:430 color:&FCGreen],
        [FootsieTarget targetWithX:260 Y:430 color:&FCGreen],

        nil
    ];
}

@end

@implementation FootsieView

@synthesize targets;

- (void)awakeFromNib
{
    self.targets = [FootsieTarget rowsOfTargets];
}

- (void)dealloc
{
    [targets release];
    [super dealloc];
}

// XXX multiple mat layouts: columns, rows, random
- (void)drawRect:(CGRect)rect
{
    [targets makeObjectsPerformSelector:@selector(draw)];
}

- (void)_updateForTouches:(NSSet*)touches
{
    for (FootsieTarget *target in targets) {
        target.isOn = NO;
        for (UITouch *touch in touches) {
            if ([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled)
                continue;
            if (CGRectContainsPoint([target rect], [touch locationInView:self]))
                target.isOn = YES;
        }
    }
    [self setNeedsDisplay];
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
