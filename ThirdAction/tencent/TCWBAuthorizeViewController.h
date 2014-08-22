//
//  TCWBAuthorizeViewController.h
//  TCWeiBoSDKDemo
//
//

#import <UIKit/UIKit.h>
#import "TCWBGlobalUtil.h"

@class TCWBAuthorizeView;

@protocol TCWBAuthorizeViewDelegate <NSObject>

@required

//授权成功回调
- (void)authorize:(TCWBAuthorizeView *)authorize didSucceedWithAccessToken:(NSString *)code; 
//授权失败回调
- (void)authorize:(TCWBAuthorizeView *)authorize didFailuredWithError:(NSError *)error;

@end

@interface TCWBAuthorizeView : UIView<UIWebViewDelegate, UIAlertViewDelegate>{
    UIWebView                                   *webView;
    UIActivityIndicatorView                     *indicatorView;
    UIButton                                    *closeButton;
    UIView                                      *modalBackgroundView;
    UIInterfaceOrientation                      previousOrientation;
    
    NSString                                    *requestURLString;
//    NSString                                    *returnCode;
    NSError                                     *err;                   // 假如授权失败，错误描述信息
}

@property (nonatomic, retain) NSString                                  *requestURLString,*returnCode,*redirectURI;
@property (nonatomic, retain) NSError                                   *err;
@property (nonatomic, assign) id<TCWBAuthorizeViewDelegate>   delegate;

- (id)initWithUrl:(NSString*)url WithDelegate:(id<TCWBAuthorizeViewDelegate>)_delegate;
- (void)show;
- (void)hide;
@end
