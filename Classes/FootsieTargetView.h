#import <UIKit/UIKit.h>

typedef void (*FootsieShape)(CGContextRef context);
typedef void (*FootsieFace)(CGContextRef context);
typedef enum FootsieSex { Female, Male } FootsieSex;

@interface FootsieTargetView : UIView
{
    UIColor *color;
    NSTimer *redrawTimer;
    BOOL isOn, isGoal;
    unsigned deathPulses;
    FootsieShape shape;
    FootsieSex sex;
}

@property(nonatomic, retain) UIColor *color;
@property FootsieShape shape;
@property FootsieSex sex;
@property BOOL isOn, isGoal;
@property unsigned deathPulses;

- (CGRect)touchRegion;

- (BOOL)isDead;

- (void)reset;

@end
