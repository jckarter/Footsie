#import "FootsieInstructionsViewController.h"
#import "misc.h"

@implementation FootsieInstructionsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    webView.frame = CGRectMake(-80, 80, 480, 320);
    webView.transform = CGAffineTransformMake(0.0, -1.0, 1.0, 0.0, 0.0, 0.0);
    [webView loadRequest:[NSURLRequest requestWithURL:_resource_url(@"Instructions", @"html")]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return orientation == UIInterfaceOrientationLandscapeLeft;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] scheme] isEqualToString:@"file"]) {
        if ([[[[request URL] path] lastPathComponent] isEqualToString:@"__DONE__"]) {
            [self.parentViewController dismissModalViewControllerAnimated:YES];
            return NO;
        } else
            return YES;
    } else {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
}

@end
