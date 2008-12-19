#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@interface FootsieGameOverView : UIView <ABNewPersonViewControllerDelegate>
{
    unsigned score;
    UILabel *scoreLabel;
    UILabel *fortuneLabel;
    UIButton *addContactButton;
}

@property unsigned score;

@end
