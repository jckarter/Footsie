#import <UIKit/UIKit.h>

typedef enum FootsiePulseViewDirection { PulseOut, PulseIn } FootsiePulseViewDirection;

@interface FootsiePulseView : UIView
{
    UIColor *color;
    FootsiePulseViewDirection direction;
}

@property(nonatomic,retain) UIColor *color;

- (FootsiePulseView*)initWithCenter:(CGPoint)point color:(UIColor*)color direction:(FootsiePulseViewDirection)dir;

- (void)pulseAnimation;

@end
