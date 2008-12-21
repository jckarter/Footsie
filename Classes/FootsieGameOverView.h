#import <UIKit/UIKit.h>

@interface FootsieGameOverView : UIView
{
    unsigned score;
    UILabel *scoreLabel;
    UILabel *fortuneLabel;
    UIButton *addContactButton;
}

@property unsigned score;

@end
