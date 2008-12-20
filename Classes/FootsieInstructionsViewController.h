#import <UIKit/UIKit.h>

@interface FootsieInstructionsViewController : UIViewController
{
    IBOutlet UIWebView *webView;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

@end

