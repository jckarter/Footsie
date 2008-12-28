#import "FootsieFlowerView.h"
#import "misc.h"

static NSArray *_flower_colors;
static UIColor *_center_color;

static unsigned _petal_counts[] = {5, 8, 13, 21};

static inline unsigned _random_petal_count()
    { return _petal_counts[rand() % (sizeof(_petal_counts)/sizeof(_petal_counts[0]))]; }

@implementation FootsieFlowerView

+ (void)initialize
{
    _flower_colors = [[NSArray alloc] initWithObjects:
        _rgba(0x99,0x00,0x00,0xff),
        _rgba(0xbb,0x44,0x00,0xff),
        _rgba(0xdd,0xcc,0x00,0xff),
        _rgba(0x00,0x00,0xbb,0xff),
        _rgba(0x55,0x00,0x99,0xff),
        _rgba(0x55,0x00,0xbb,0xff),
        _rgba(0xcc,0xcc,0xcc,0xff),
        nil
    ];

    _center_color = [_rgba(0xff,0xff,0x00,0xff) retain];
}

- (id)initAtPoint:(CGPoint)point forScore:(unsigned)score
{
    if (self = [super init]) {
        CGFloat factor = log(score + 1) + 1.0;
        radius = _rand_between(10.0 + factor, 15.0 + factor);
        CGFloat slush = radius + 1.0;
        self.frame = CGRectMake(point.x - slush, point.y - slush, slush*2, slush*2);
        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[_flower_colors randomObject] CGColor]);
    CGContextTranslateCTM(context, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    unsigned num_petals = _random_petal_count();
    CGFloat center_radius = _rand_between(0.3*radius, 0.4*radius);
    CGFloat petal_minor_radius = center_radius * 8.0/(num_petals+sqrt(num_petals));

    CGContextRotateCTM(context, _rand_between(0.0, 2*M_PI));
    for (unsigned i = 0; i < num_petals; ++i) {
        CGContextSaveGState(context);
        CGContextRotateCTM(context, i * 2*M_PI / num_petals);
        CGContextFillEllipseInRect(context, CGRectMake(-center_radius, -petal_minor_radius, center_radius+radius, petal_minor_radius*2));
        CGContextRestoreGState(context);
    }
    CGContextSetFillColorWithColor(context, _center_color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(-center_radius, -center_radius, center_radius*2, center_radius*2));
}

@end
