#import <UIKit/UIKit.h>

@interface FootsieGameOverView : UIView
{
    unsigned score, talliedScore;
    UILabel *scoreLabel;
    UILabel *fortuneLabel;
    UIButton *addContactButton;
}

@property unsigned score, talliedScore;

@end
