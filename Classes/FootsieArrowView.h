#import <UIKit/UIKit.h>

@interface FootsieArrowView : UIView
{
    CGPoint from, to, control;
}

- (id)initFromPoint:(CGPoint)from toPoint:(CGPoint)to aroundTargets:(NSSet*)targets;

@end
