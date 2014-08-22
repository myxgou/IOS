//
//  ThirdAction.h
//  ThirdAction
//
//  Created by wac on 14-8-13.
//  Copyright (c) 2014年 com.myxgou.third. All rights reserved.
//


/*
                                    🐶                                        🐶
                                        🐶                                  🐶
                                            🐶                            🐶
                                                🐶                      🐶
                                                    🐶                🐶
 🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶
 🐶                                         用户须知                                                                       🐶
 🐶  在targets上找到对应的项目，选择info，然后在url types上添加如下                  🐶
 🐶   1.腾讯微博：wbKey;                                                                                          🐶
 🐶   2.新浪微博：sinaweibosso.Key;                                                                        🐶
 🐶   3.微信分享：wxKey;                                                                                          🐶
 🐶   4.qq登录：tencentKey;                                                                                      🐶
 🐶   Btw:需要在您的项目里引入第三方静态库:                                                         🐶
 🐶   1>微信的libWeChatSDK.a,                                                                                🐶
 🐶   2>腾讯微博libTcWeiboSDK.a，                                                                         🐶
 🐶   3>qq的TencentOpenAPI.framework+TencentOpenApi_IOS_Bundle.bundle,   🐶
 🐶   4>新浪微博的WeiboSDK.bundle                                                                       🐶
 🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶

 
 */




@protocol ThirdActionProtocol <NSObject>
@required

//sina微博的信息
/*
 @return @{@"appkey":**,@"secret":**,@"redirect":**}
 */
-(NSDictionary *)fillSinaInfo;
//腾讯微博的信息
/*
 @return @{@"appkey":**,@"secret":**,@"redirect":**}
 */
-(NSDictionary *)fillTencentInfo;
//qq客户端信息
/*
 @return appkey
 */
-(NSString *)fillQQInfo;
//微信客户端信息
/*
 @return appkey
 */
-(NSString *)fillWechatInfo;
@end

#import <Foundation/Foundation.h>
#define AccessTokenKey          @"token"
#define ExpirationDateKey       @"date"
#define ExpireTimeKey           @"time"
#define UserIDKey               @"userid"
#define OpenIdKey               @"openid"
#define OpenKeyKey              @"key"
#define RefreshTokenKey         @"rtoken"
#define NameKey                 @"name"
#define SSOAuthKey              @"auth"
typedef enum
{
    qqClient,
    sinaWeibo,
    tcWeibo,
    weChatCircle,
    weChatFriend,
    weChat
}PlatformType;

@interface ThirdAction : NSObject
@property(nonatomic,assign)id<ThirdActionProtocol> thirdActionDelegate;
@property(nonatomic,strong)NSString *loginSucessNotifyName,/*登录成功的通知*/
                                                                *loginFailNotifyName,/*登录失败的通知*/
                                                                *loginOutNotifyName,/*退出的通知*/
                                                                *shareSucessNotifyName,/*分享成功的通知*/
                                                                *shareFailNotifyName;/*分享失败的通知*/
+(ThirdAction*)instance;
//实现注册通知集合
-(void)registerActionsCollection;
//第三方登录
-(void)thirdLoginBySign:(PlatformType)sign;
//分享文本
-(void)thirdShareTextWithTitle:(NSString *)title andMessage:(NSString*)message andUrl:(NSString *)url WithType:(PlatformType)sign;
//分享多媒体，only文本+图片
-(void)thirdShareMediaWithTitle:(NSString *)title andMessage:(NSString*)message andUrl:(NSString *)url andImage:(UIImage *)image  WithType:(PlatformType)sign;
//注册各平台，根据thirdActionDelegate的委托
-(void)rdyRegisterAllFlatform;
//这个是第三方平台的回调要写到系统的方法里，重写
//- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
-(BOOL)handleOpenURLWithUrl:(NSURL *)url;
@end
