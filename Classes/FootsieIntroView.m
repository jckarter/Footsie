#import "FootsieIntroView.h"
#import "FootsieAppDelegate.h"
#import "FootsieViewController.h"
#import "FootsieInstructionsViewController.h"

@implementation FootsieIntroView

- (id)initWithBackground:(NSString*)bgimage instructions:(BOOL)instructions
{
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.bounds = CGRectMake(0, 0, 290, 100);
        self.userInteractionEnabled = instructions;

        UIImageView *introBackground = [[UIImageView alloc] initWithImage:
            [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:bgimage ofType:@"png"]]
        ];
        introBackground.frame = CGRectMake(0, 0, 290, 100);
        introBackground.opaque = NO;
        introBackground.backgroundColor = [UIColor clearColor];

        UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
        UIFont *plainFont = [UIFont systemFontOfSize:13];
        UILabel *introLabel = [[[UILabel alloc] init] autorelease];
        introLabel.frame = CGRectMake(14, 47 + (instructions ? -1 : 13), 270, 15);
        introLabel.font = plainFont;
        introLabel.text = @"Touch and hold all of the angry faces to start.";
        introLabel.textColor = [UIColor whiteColor];
        introLabel.textAlignment = UITextAlignmentCenter;
        introLabel.lineBreakMode = UILineBreakModeWordWrap;
        introLabel.numberOfLines = 0;
        introLabel.opaque = NO;
        introLabel.backgroundColor = [UIColor clearColor];

        [self addSubview:introBackground];
        [self addSubview:introLabel];

        if (instructions) {
            UIButton *instructionsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            instructionsButton.frame = CGRectMake(85, 67, 130, 29);
            instructionsButton.font = boldFont;
            [instructionsButton setTitle:@"Instructions" forState:UIControlStateNormal];
            [instructionsButton addTarget:[[UIApplication sharedApplication] delegate] action:@selector(showInstructions:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:instructionsButton];
        }
    }
    return self;
}

@end
