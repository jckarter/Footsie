#import <UIKit/UIKit.h>


typedef struct FootsieColor { CGFloat r, g, b, a; } FootsieColor;

extern FootsieColor FCRed, FCGreen, FCBlue, FCYellow, FCOrange;


@interface FootsieTarget : NSObject
{
    CGFloat x, y;
    FootsieColor *color;
    BOOL isOn;
}

- (FootsieTarget*)initWithX:(CGFloat)x Y:(CGFloat)y color:(FootsieColor*)color;
+ (FootsieTarget*)targetWithX:(CGFloat)x Y:(CGFloat)y color:(FootsieColor*)color;

- (void)draw;

- (CGRect)rect;
- (CGRect)innerRect;

@property CGFloat x, y;
@property FootsieColor *color;
@property BOOL isOn;

+ (NSArray*)rowsOfTargets;

@end


@interface FootsieView : UIView
{
    NSArray *targets;
}

@property(nonatomic, retain) NSArray *targets;

@end
