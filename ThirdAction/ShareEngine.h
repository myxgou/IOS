//
//  ShareEngine.h
//  ShareEngineExample
//
//  Created by 陈欢 on 13-10-8.
//  Copyright (c) 2013年 陈欢. All rights reserved.
//




#import <Foundation/Foundation.h>
#import "WXApi.h"
#import "TCWBEngine.h"
#import "SinaWeibo.h"
#import "SinaWeiboRequest.h"
#import "qq/TencentOpenAPI.framework/Headers/TencentOAuth.h"
#import "qq/TencentOpenAPI.framework/Headers/QQApi.h"
#import "ThirdAction.h"
@protocol ShareEngineDelegate;

@interface ShareEngine : NSObject<WXApiDelegate,SSODelegate,SinaWeiboDelegate, SinaWeiboRequestDelegate,UIAlertViewDelegate,TencentLoginDelegate,TencentSessionDelegate>
{
    //TcWeibo
    TCWBEngine                  *tcWeiboEngine;
    SinaWeibo                       *sinaWeiboEngine;
    TencentOAuth                *tencentHanle;
//    记录未登录情况下分享的内容
    NSDictionary *recordUnLoginActionInfo;
}
//分享成功的回调。
@property(nonatomic,copy)void(^shareEngineDidLogIn)(PlatformType,NSDictionary *);
@property(nonatomic,copy)void(^shareEngineDidLogOut)(PlatformType);
@property(nonatomic,copy)void(^shareEngineLoginFail)();
@property(nonatomic,copy)void(^shareEngineSendSuccess)();
@property(nonatomic,copy)void(^shareEngineSendFail)();
+ (ShareEngine *) sharedInstance;
/**
 *@description 实现第三方回调跳转
 *@return BOOL
 */
- (BOOL)handleOpenURL:(NSURL *)url;
/**
 *@description 注册app
 *@return void
 */
//-(void)registerAppBySign:(PlatformType)sign andKey:(NSString*)appKey,...;
-(void)registerAppBySign:(PlatformType)sign andKey:(NSString*)appKey andSecret:(NSString *)secret andRedirectURI:(NSString *)url;
/**
 *@description 给已经初始化的第三方平台给予本地已经储存的信息。
 */
- (void)setUpStoreLocalDataApp;
/**
 *@description 判断是否登录
 *@param PlatformType:微博类型
 */
- (BOOL)isLogin:(PlatformType)sign;

/**
 *@description 微博登录
 *@param PlatformType:微博类型
 */
- (void)loginWithType:(PlatformType)sign;

/**
 *@description 退出微博
 *@param PlatformType:微博类型
 */
- (void)logOutWithType:(PlatformType)sign;

/**
 *@description 发送微信消息
 *@param message:文本消息 url:分享链接,image图 PlatformType:微信消息类型,缺省参数分别是url
 */
- (void)shareMediaWithTitle:(NSString *)title message:(NSString*)message WithType:(PlatformType)sign,...;
/**
 *@description 发送微博成功
 *@param message:文本消息 PlatformType:微博类型
 */


@end
