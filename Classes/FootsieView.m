#import "FootsieView.h"
#import "misc.h"
#include <stdlib.h>
#include <math.h>

@interface FootsieView ()

- (void)_updateForTouches:(NSSet*)touches;
- (void)_drawGoalTransition;
- (BOOL)_goalsReached;
- (void)_moveRandomGoal;
- (UIColor*)_backgroundColor;

- (void)addGoal:(FootsieTargetView*)t;
- (void)removeGoal:(FootsieTargetView*)t;
- (void)moveGoal:(FootsieTargetView*)from to:(FootsieTargetView*)to;

@end

@implementation FootsieView

@synthesize targets;

- (void)addGoal:(FootsieTargetView*)t
{
    t.isGoal = YES;
    [goalTargets addObject:t];
}

- (void)removeGoal:(FootsieTargetView*)t
{
    t.isGoal = NO;
    [goalTargets removeObject:t];
}

- (UIColor*)_backgroundColor
{
    return [UIColor blackColor];
}

- (void)moveGoal:(FootsieTargetView*)from to:(FootsieTargetView*)to
{
    [self removeGoal:from];
    [self addGoal:to];
    fromGoal = from; toGoal = to;
}

- (void)awakeFromNib
{
    NSMutableArray *targets_tmp = [NSMutableArray array];
    goalTargets = [[NSMutableSet alloc] init];

    for (UIView *subview in [self subviews])
        if ([subview isKindOfClass:[FootsieTargetView class]]) {
            [targets_tmp addObject:subview]; 
            if (subview.tag == 1)
                [self addGoal:(FootsieTargetView*)subview];
        }
    targets = [[NSArray alloc] initWithArray:targets_tmp];
    fromGoal = toGoal = nil;

    NSLog(@"%d targets", [targets count]);
    NSLog(@"%d goals", [goalTargets count]);
}

- (void)dealloc
{
    [targets release];
    [goalTargets release];
    [super dealloc];
}

- (void)_drawGoalTransition
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGFloat stroke_color[4] = { 1.0, 0.0, 0.0, 1.0 };
    CGContextSetLineWidth(context, 3.0);
    CGContextSetStrokeColor(context, stroke_color);

    CGContextBeginPath(context);
    CGContextMoveToPoint(context, fromGoal.center.x, fromGoal.center.y);
    CGContextAddLineToPoint(context, toGoal.center.x, toGoal.center.y);

    CGContextStrokePath(context);
}

- (void)_updateForTouches:(NSSet*)touches
{
    if ([self _goalsReached])
        [self _moveRandomGoal];

    for (FootsieTargetView *target in targets) {
        BOOL isOn = NO;
        for (UITouch *touch in touches) {
            if ([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled)
                continue;
            if (CGRectContainsPoint(target.frame, [touch locationInView:self]))
                isOn = YES;
        }
        target.isOn = isOn;
    }
}

- (BOOL)_goalsReached
{
    for (FootsieTargetView *target in goalTargets) {
        if (!target.isOn)
            return NO;
    }
    return YES;
}

- (void)_moveRandomGoal
{
    FootsieTargetView *from = [goalTargets randomObject], *to;
    do { to = [targets randomObject]; } while (to.isGoal);
    [self moveGoal:from to:to];
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
