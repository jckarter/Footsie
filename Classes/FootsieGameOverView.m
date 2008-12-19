#import "FootsieGameOverView.h"

@interface FootsieGameOverView ()

- (IBAction)_resetGame:(id)sender;
@end

@implementation FootsieGameOverView

@synthesize score;

- (void)setScore:(unsigned)s
{
    score = s;
    scoreLabel.text = [NSString stringWithFormat:@"Your Score: %u", score];
}

- (IBAction)_resetGame:(id)sender
{
    [self.superview _resetGame];
}

- (id)init
{
    if (self = [super init]) {

        NSLog(@"Futura font names:");
        for (NSString *fontName in [UIFont fontNamesForFamilyName:@"Futura"])
            NSLog(@"    %@", fontName);

        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.bounds = CGRectMake(0, 0, 300, 134);
        
        UIFont *font = [UIFont boldSystemFontOfSize:16];

        UIImageView *gameOverBackground = [[UIImageView alloc] initWithImage:
            [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GameOver" ofType:@"png"]]
        ];
        gameOverBackground.frame = CGRectMake(0, 0, 300, 134);
        gameOverBackground.opaque = NO;
        gameOverBackground.backgroundColor = [UIColor clearColor];

        scoreLabel = [[[UILabel alloc] init] autorelease];
        scoreLabel.frame = CGRectMake(0, 58, 300, 25);
        scoreLabel.font = font;
        scoreLabel.textColor = [UIColor whiteColor];
        scoreLabel.textAlignment = UITextAlignmentCenter;
        scoreLabel.opaque = NO;
        scoreLabel.backgroundColor = [UIColor clearColor];

        self.score = 0;

        UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        resetButton.frame = CGRectMake(100, 92, 100, 28);
        resetButton.font = font;
        [resetButton setTitle:@"Play Again" forState:UIControlStateNormal];
        [resetButton addTarget:self action:@selector(_resetGame:) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:gameOverBackground];
        [self addSubview:scoreLabel];
        [self addSubview:resetButton];
    }
    return self;
}

@end
