#import <UIKit/UIKit.h>

@interface FootsieArrowView : UIView
{
    CGPoint from, to;
}

- (id)initFromPoint:(CGPoint)from toPoint:(CGPoint)to;

@end
