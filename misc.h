#import <UIKit/UIKit.h>

@interface NSArray (Footsie)

- (id)randomObject;

@end

@interface NSSet (Footsie)

- (id)randomObject;

@end

static inline CGFloat _rand_between(CGFloat lo, CGFloat hi)
{
    CGFloat r = (CGFloat)rand()/(CGFloat)RAND_MAX;
    CGFloat spread = hi - lo;
    CGFloat ret = r * spread + lo;

    return ret;
}

static inline CGFloat _epsilon(CGFloat center, CGFloat error)
{
    return _rand_between(center - error, center + error);
}

static inline UIColor *_asleep(UIColor *c)
{
    CGFloat const *comp = CGColorGetComponents(c.CGColor);

    return [UIColor colorWithRed:(comp[0] + 0.6) * 0.4
                    green:       (comp[1] + 0.6) * 0.4
                    blue:        (comp[2] + 0.6) * 0.4
                    alpha:       comp[3]];
}

static inline UIColor *_half_asleep(UIColor *c)
{
    CGFloat const *comp = CGColorGetComponents(c.CGColor);

    return [UIColor colorWithRed:(comp[0] + 0.8) * 0.4
                    green:       (comp[1] + 0.8) * 0.4
                    blue:        (comp[2] + 0.8) * 0.4
                    alpha:       comp[3]];
}

static inline UIColor *_angry(UIColor *c)
{
    CGFloat const *comp = CGColorGetComponents(c.CGColor);

    return [UIColor colorWithRed:comp[0]
                    green:       comp[1] * 0.4
                    blue:        comp[2] * 0.4
                    alpha:       comp[3]];
}

static inline UIColor *_happy(UIColor *c)
{
    return c;
}

static inline UIColor *_with_alpha(UIColor *c, CGFloat alpha)
{
    CGFloat const *comp = CGColorGetComponents(c.CGColor);

    return [UIColor colorWithRed:comp[0]
                    green:       comp[1]
                    blue:        comp[2]
                    alpha:       alpha];
}

static inline UIColor *_rgba(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
    return [UIColor colorWithRed:(CGFloat)r/255.0
                    green:(CGFloat)g/255.0
                    blue:(CGFloat)b/255.0
                    alpha:(CGFloat)a/255.0];
}

