#import <AudioToolbox/AudioToolbox.h>
#import "FootsieGameOverView.h"
#import "FootsieAppDelegate.h"
#import "FootsieViewController.h"
#import "FootsieFlowerView.h"
#import "FootsieView.h"
#import "misc.h"

static NSArray *coldFishFortunes, *lukeWarmLukeFortunes, *hotTamaleFortunes;
static BOOL FLOWER_SHOWER;

@interface FootsieGameOverView ()

- (IBAction)_resetGame:(id)sender;
- (void)_dropFlower:(NSTimer*)timer;
- (void)_dropFlowerAnimationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context;
- (void)_dropFlowersInSuperview:(NSTimer*)timer;

@end

@implementation FootsieGameOverView

@synthesize score, talliedScore;

+ (void)initialize
{
    FLOWER_SHOWER = [[NSUserDefaults standardUserDefaults] boolForKey:@"flowerShower"];

    coldFishFortunes = [[NSArray alloc] initWithObjects:
        @"Perhaps it wasn't meant to be.",
        @"Maybe you should just stay friends.",
        @"Maybe you should start with coffee first.",
        nil
    ];

    lukeWarmLukeFortunes = [[NSArray alloc] initWithObjects:
        @"You two should totally hang out sometime.",
        @"You two make a great pair.",
        @"How about another round? This one's on me.",
        nil
    ];

    hotTamaleFortunes = [[NSArray alloc] initWithObjects:
        @"I feel like you two have known each other all your lives.",
        @"You two should play somewhere a little quieter.",
        @"Is it just me, or are there bells in the distance?",
        nil
    ];
}

- (void)setScore:(unsigned)s
{
    score = s;
    self.talliedScore = 0;

    if (score < 10)
        fortuneLabel.text = [coldFishFortunes randomObject];
    else if (score < 25)
        fortuneLabel.text = [lukeWarmLukeFortunes randomObject];
    else
        fortuneLabel.text = [hotTamaleFortunes randomObject];

    if (score < 10)
        addContactButton.alpha = 0.0;
    else
        addContactButton.alpha = 1.0;
}

- (void)setTalliedScore:(unsigned)s
{
    talliedScore = s;
    scoreLabel.text = talliedScore == 0 && score != 0
        ? @"Your Score: -"
        : [NSString stringWithFormat:@"Your Score: %u", talliedScore];

    if (talliedScore == score) {
        fortuneLabel.alpha = 1.0;
        AudioServicesPlaySystemSound([(FootsieView*)self.superview cashSound]);
    } else
        fortuneLabel.alpha = 0.0;
}

- (IBAction)_resetGame:(id)sender
{
    [self.superview _resetGame];
}

- (id)init
{
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.bounds = CGRectMake(0, 0, 300, 180);
        
        UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
        UIFont *plainFont = [UIFont systemFontOfSize:14];

        UIImageView *gameOverBackground = [[UIImageView alloc] initWithImage:
            [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GameOver" ofType:@"png"]]
        ];
        gameOverBackground.frame = CGRectMake(0, 0, 300, 180);
        gameOverBackground.opaque = NO;
        gameOverBackground.backgroundColor = [UIColor clearColor];

        scoreLabel = [[[UILabel alloc] init] autorelease];
        scoreLabel.frame = CGRectMake(0, 58, 300, 25);
        scoreLabel.font = boldFont;
        scoreLabel.textColor = [UIColor whiteColor];
        scoreLabel.textAlignment = UITextAlignmentCenter;
        scoreLabel.opaque = NO;
        scoreLabel.backgroundColor = [UIColor clearColor];

        fortuneLabel = [[[UILabel alloc] init] autorelease];
        fortuneLabel.frame = CGRectMake(10, 85, 280, 50);
        fortuneLabel.font = plainFont;
        fortuneLabel.textColor = [UIColor whiteColor];
        fortuneLabel.textAlignment = UITextAlignmentCenter;
        fortuneLabel.lineBreakMode = UILineBreakModeWordWrap;
        fortuneLabel.numberOfLines = 2;
        fortuneLabel.opaque = NO;
        fortuneLabel.backgroundColor = [UIColor clearColor];

        self.score = 0;

        addContactButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        addContactButton.frame = CGRectMake(10, 144, 28, 28);
        addContactButton.font = boldFont;
        [addContactButton addTarget:[[UIApplication sharedApplication] delegate] action:@selector(addContact:) forControlEvents:UIControlEventTouchUpInside];

        UIButton *instructionsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        instructionsButton.frame = CGRectMake(44, 144, 110, 25);
        instructionsButton.font = boldFont;
        [instructionsButton setTitle:@"Instructions" forState:UIControlStateNormal];
        [instructionsButton addTarget:[[UIApplication sharedApplication] delegate] action:@selector(showInstructions:) forControlEvents:UIControlEventTouchUpInside];

        UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        resetButton.frame = CGRectMake(160, 144, 110, 25);
        resetButton.font = boldFont;
        [resetButton setTitle:@"Play Again" forState:UIControlStateNormal];
        [resetButton addTarget:self action:@selector(_resetGame:) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:gameOverBackground];
        [self addSubview:scoreLabel];
        [self addSubview:fortuneLabel];
        [self addSubview:addContactButton];
        [self addSubview:instructionsButton];
        [self addSubview:resetButton];
    }
    return self;
}

- (void)didMoveToSuperview
{
    if (self.superview) {
        [[NSTimer
            scheduledTimerWithTimeInterval:0.4
            target:self
            selector:@selector(_dropFlowersInSuperview:)
            userInfo:nil
            repeats:NO
        ] retain];
    }
}

- (void)_dropFlowersInSuperview:(NSTimer*)timer
{
    CGFloat timerDelay = 0.15, timerDelayDelta = 0.15;
    for (UIView *view in [self.superview subviews]) {
        if ([view isKindOfClass:[FootsieFlowerView class]]) {
            [[NSTimer
                scheduledTimerWithTimeInterval:timerDelay
                target:self
                selector:@selector(_dropFlower:)
                userInfo:[view retain]
                repeats:NO
            ] retain];
            timerDelay += timerDelayDelta;
            timerDelayDelta *= 0.95;
        }
    }
}

- (void)_dropFlower:(NSTimer*)timer
{
    UIView *flower = [timer userInfo];

    if (FLOWER_SHOWER) {
        if (flower.superview) {
            [UIView beginAnimations:nil context:flower];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationDidStopSelector:@selector(_dropFlowerAnimationDidStop:finished:context:)];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];

            flower.center = CGPointMake(flower.center.x + 320.0, flower.center.y);
            flower.transform = CGAffineTransformMakeRotation(_rand_between(-1.0, 1.0));

            [UIView commitAnimations];
        } else {
            [flower release];
        }
    } else {
        [flower release];    
        ++self.talliedScore;
        AudioServicesPlaySystemSound([(FootsieView*)self.superview coinSound]);
    }

    [timer release];
}

- (void)_dropFlowerAnimationDidStop:(NSString*)animationID finished:(BOOL)finished context:(void*)context
{
    UIView *flower = (UIView*)context;
    [flower removeFromSuperview];
    [flower release];
    ++self.talliedScore;

    AudioServicesPlaySystemSound([(FootsieView*)self.superview coinSound]);
}

@end
