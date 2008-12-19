#import "FootsiePausedView.h"

@implementation FootsiePausedView

- (id)init
{
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.bounds = CGRectMake(0, 0, 270, 65);

        UIImageView *pausedBackground = [[UIImageView alloc] initWithImage:
            [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Paused" ofType:@"png"]]
        ];
        pausedBackground.frame = CGRectMake(0, 0, 270, 65);
        pausedBackground.opaque = NO;
        pausedBackground.backgroundColor = [UIColor clearColor];

        [self addSubview:pausedBackground];
    }
    return self;
}

@end
