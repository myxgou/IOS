//
//  ShareEngine.m
//  ShareEngineExample
//
//  Created by 陈欢 on 13-10-8.
//  Copyright (c) 2013年 陈欢. All rights reserved.
//

#import "ShareEngine.h"

@implementation ShareEngine
@synthesize shareEngineDidLogIn,shareEngineLoginFail,shareEngineDidLogOut,shareEngineSendFail,shareEngineSendSuccess;

static NSString *SinaGetUserNameHostUrl = @"https://api.weibo.com/2/users/show.json";
static ShareEngine *sharedSingleton_ = nil;

+ (ShareEngine *) sharedInstance
{
    
    static ShareEngine *sharedSingleton_ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton_ = [[ShareEngine alloc] init];
    });
    
    return sharedSingleton_;
}
#pragma mark - register third platform
-(void)registerAppBySign:(PlatformType)sign andKey:(NSString*)appKey andSecret:(NSString *)secret andRedirectURI:(NSString *)url{
    if(appKey==nil)return;
    
    switch (sign) {
        case qqClient:
            tencentHanle = [[TencentOAuth alloc] initWithAppId:appKey andDelegate:self];
            break;
        case sinaWeibo:
            NSAssert(secret&&url, @"sinaweibo weibo secret and url mustn't be nil");
            sinaWeiboEngine = [[SinaWeibo alloc] initWithAppKey:appKey appSecret:secret appRedirectURI:url andDelegate:self];
            break;
        case tcWeibo:
            NSAssert(secret&&url, @"tcweibo weibo secret and url mustn't be nil");
            tcWeiboEngine = [[TCWBEngine alloc] initWithAppKey:appKey andSecret:secret andRedirectUrl:url];
            break;
        case weChat:
            [WXApi registerApp:appKey];
            break;
        default:
            break;
    }
}


- (void)setUpStoreLocalDataApp
{
    //向微信注册
    [self tcWeiboReadAuthData];
    [self sinaWeiboReadAuthData];
}

#pragma -mark you must written in the function of the app delegate
- (BOOL)handleOpenURL:(NSURL *)url{
    BOOL weiboRet = NO;
    if ([url.absoluteString hasPrefix:@"sina"])
    {
        
        if([url.absoluteString rangeOfString:@"WBOpenURLContextResultCanceld"].location != NSNotFound){
            if(shareEngineLoginFail)
                shareEngineLoginFail();
        }
        weiboRet = [sinaWeiboEngine handleOpenURL:url];
    }
    else if([url.absoluteString hasPrefix:@"wb"])
    {
        weiboRet = [tcWeiboEngine handleOpenURL:url delegate:self];
    }
    else if([url.absoluteString hasPrefix:@"wx"])
    {
        weiboRet = [WXApi handleOpenURL:url delegate:self];
    }else{
        weiboRet = [TencentOAuth HandleOpenURL:url];
    }
    return weiboRet;
}


#pragma mark - third share main entrance
- (void)shareMediaWithTitle:(NSString *)title message:(NSString*)message WithType:(PlatformType)sign,...{
    //    找到缺省参数，url，和image。
    va_list valist;
    va_start(valist, sign);
    id object = nil;
    NSString *url = nil;
    UIImage *image = nil;
    while ((object=va_arg(valist, id))!=nil){
        if([object isKindOfClass:[NSString class]]){
            url = object;
        }else if([object isKindOfClass:[UIImage class]]){
            image = object;
        }
    }
    va_end(valist);
    if(weChatCircle == sign)
    {
        
        return image ? [self sendWeChatContentTitle:title WithMessage:message WithUrl:url image:image WithScene:WXSceneTimeline] : [self sendWeChatFriendPostMessage:message];
    }
    else if(weChatFriend == sign)
    {
        return image ? [self sendWeChatContentTitle:title WithMessage:message WithUrl:url image:image WithScene:WXSceneSession] : [self sendWeChatPostMessage:message];
    }
    NSString *mergeMessage = message;
    if(url.length>0)
        mergeMessage = [mergeMessage stringByAppendingFormat:@"\n%@",url];
    if (NO == [self isLogin:sign])
    {
        
        recordUnLoginActionInfo = image ?
                                                        @{@"image":image,@"message":mergeMessage} : @{@"message":mergeMessage};
        [self loginWithType:sign];
        return;
    }
    
    recordUnLoginActionInfo = nil;
    
    if (sinaWeibo == sign){
        image ? [self sinaWeiboPostImage:image message:mergeMessage] : [self sinaWeiboWithMessage:mergeMessage];
    }else if (tcWeibo == sign){
        image ? [self tcWeiboSendImageAndUrlWithMessage:mergeMessage image:image] : [self tcWeiboSendTextWithMessage:mergeMessage];
    }
}

#pragma mark - third login main entrance
- (void)loginWithType:(PlatformType)sign
{
    if (sinaWeibo == sign)
    {
        
        [sinaWeiboEngine logIn];
    }
    else if(tcWeibo == sign)
    {
        [self tcWeiboLogin];
    }
    else if(qqClient == sign)
    {
        [self loginQQClient];
    }
}

- (void)logOutWithType:(PlatformType)sign
{
    if (sinaWeibo == sign)
    {
        [sinaWeiboEngine logOut];
    }
    else if(tcWeibo == sign)
    {
        [tcWeiboEngine logOutWithDelegate:self];
    }
}

- (BOOL)isLogin:(PlatformType)sign
{
    if (sinaWeibo == sign)
    {
        return [sinaWeiboEngine isLoggedIn];
    }
    else if(tcWeibo == sign)
    {
        return [tcWeiboEngine isLoggin];
    }
    else
    {
        return NO;
    }
}


- (void)logOutSuccess:(PlatformType)sign
{
    if(shareEngineDidLogOut)
        shareEngineDidLogOut(sign);
}

- (void)loginFail
{
    if(shareEngineLoginFail)
        shareEngineLoginFail();
}

- (void)weiboSendSuccess
{
    if(shareEngineSendSuccess)
        shareEngineSendSuccess();
}

- (void)weiboSendFail:(NSError *)error
{
    if (shareEngineSendFail)
        shareEngineSendFail();
    
}

/*🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷🌷*/

#pragma mark - qqclient login

-(void)loginQQClient{
    if([TencentOAuth iphoneQQInstalled]){
        if([TencentOAuth iphoneQQSupportSSOLogin]){
            [tencentHanle authorize:@[kOPEN_PERMISSION_GET_USER_INFO,
                                      kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                                      kOPEN_PERMISSION_ADD_IDOL,
                                      kOPEN_PERMISSION_ADD_PIC_T,
                                      kOPEN_PERMISSION_ADD_SHARE,
                                      kOPEN_PERMISSION_CHECK_PAGE_FANS,
                                      kOPEN_PERMISSION_DEL_IDOL,
                                      kOPEN_PERMISSION_DEL_T,
                                      kOPEN_PERMISSION_GET_FANSLIST,
                                      kOPEN_PERMISSION_GET_IDOLLIST,
                                      kOPEN_PERMISSION_GET_INFO,
                                      kOPEN_PERMISSION_GET_OTHER_INFO,
                                      kOPEN_PERMISSION_GET_REPOST_LIST] inSafari:YES];
        }else{
           
            return [self showAlertView:^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"系统提示" message:@"您的手机QQ，暂不支持SSO登录,确定安装最新的吗？" delegate:self cancelButtonTitle:@"暂不" otherButtonTitles:@"确定", nil];
                alertView.tag = QQClientTag;
                return alertView;
            }()];
        }
    }else{
        return [self showAlertView:^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"系统提示" message:@"您尚未安装手机QQ,确定安装吗？" delegate:self cancelButtonTitle:@"暂不" otherButtonTitles:@"确定", nil];
            alertView.tag = QQClientTag;
            return alertView;
        }()];
    }
    return;
}

#pragma mark qq login delegate
- (void)getUserInfoResponse:(APIResponse*) response{
    
    if(response.retCode == 0){
        NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  tencentHanle.accessToken, AccessTokenKey,
                                  tencentHanle.expirationDate, ExpirationDateKey,
                                  tencentHanle.openId, UserIDKey,
                                  response.jsonResponse[@"nickname"],NameKey,
                                  sinaWeiboEngine.refreshToken, RefreshTokenKey, nil];
        if(shareEngineDidLogIn)
        shareEngineDidLogIn(qqClient,authData);
    }
    else{
        if(shareEngineLoginFail)
            shareEngineLoginFail();
    }
}

/**
 * 登录成功后的回调
 */
-(void)tencentDidLogin{
    [tencentHanle getUserInfo];
}


/**
 * 登录失败后的回调
 * param cancelled 代表用户是否主动退出登录
 */
-(void)tencentDidNotLogin:(BOOL)cancelled{
    if(shareEngineLoginFail)
        shareEngineLoginFail();
}
//登录时网络有问题的回调
-(void)tencentDidNotNetWork{
    [self showAlertView:[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"网络异常，请稍后再试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil]];
    if(shareEngineLoginFail)
        shareEngineLoginFail();
   
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex != alertView.cancelButtonIndex)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:alertView.tag == QQClientTag ? [QQApi getQQInstallURL] : [WXApi getWXAppInstallUrl]]];
    if(shareEngineLoginFail)
        shareEngineLoginFail();
}

/*🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻🌻*/


#pragma mark - sinaWeibo method
//get sina weibo user base info
- (void)sinaWeiboStoreAuthData{
    
    NSString *getUserInfoFromSina = [NSString stringWithFormat:@"%@?access_token=%@&uid=%@",SinaGetUserNameHostUrl,sinaWeiboEngine.accessToken,sinaWeiboEngine.userID];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:getUserInfoFromSina]];
        NSError *error = nil;
        NSDictionary *parseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error){
                return [self showAlertView:[[UIAlertView alloc] initWithTitle:@"系统提示" message:@"数据解析失败，请稍后再试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil]];
            }
            NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                                      sinaWeiboEngine.accessToken, AccessTokenKey,
                                      sinaWeiboEngine.expirationDate, ExpirationDateKey,
                                      sinaWeiboEngine.userID, UserIDKey,
                                      parseDic[@"screen_name"],NameKey,
                                      sinaWeiboEngine.refreshToken, RefreshTokenKey, nil];
            [[NSUserDefaults standardUserDefaults] setObject:authData forKey:@"SinaWeiboAuthData"];
//                登录成功
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (shareEngineDidLogIn){

                shareEngineDidLogIn(sinaWeibo,authData);
//                看是否还有之前因为没有登录导致没分享出去的内容，如果还有登录后就继续分享。
                if(recordUnLoginActionInfo){
                    UIImage *image = recordUnLoginActionInfo[@"image"];
                    NSString *mergeMessage = recordUnLoginActionInfo[@"message"];
                        image ? [self sinaWeiboPostImage:image message:mergeMessage] : [self sinaWeiboWithMessage:mergeMessage];
                    recordUnLoginActionInfo = nil;
                }
            }
        });
    });
}
//sina weibo logout and clear login data.
- (void)sinaWeiboRemoveAuthData{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SinaWeiboAuthData"];
    [sinaWeiboEngine removeAuthData];
}
//get cache data from app
- (void)sinaWeiboReadAuthData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *sinaweiboInfo = [defaults objectForKey:@"SinaWeiboAuthData"];
    if ([sinaweiboInfo objectForKey:AccessTokenKey] && [sinaweiboInfo objectForKey:ExpirationDateKey] && [sinaweiboInfo objectForKey:UserIDKey])
    {
        sinaWeiboEngine.accessToken = [sinaweiboInfo objectForKey:AccessTokenKey];
        sinaWeiboEngine.expirationDate = [sinaweiboInfo objectForKey:ExpirationDateKey];
        sinaWeiboEngine.userID = [sinaweiboInfo objectForKey:UserIDKey];
    }
}
//sina weibo send text message
- (void)sinaWeiboWithMessage:(NSString*)message
{
    [sinaWeiboEngine requestWithURL:@"statuses/update.json"
                             params:[NSMutableDictionary dictionaryWithObjectsAndKeys:message, @"status", nil]
                         httpMethod:@"POST"
                           delegate:self];
}
//sina weibo send image message
- (void)sinaWeiboPostImage:(UIImage*)image message:(NSString*)message
{
    [sinaWeiboEngine requestWithURL:@"statuses/upload.json"
                             params:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     message, @"status",
                                     image, @"pic", nil]
                         httpMethod:@"POST"
                           delegate:self];
}
#pragma mark - SinaWeibo Delegate
- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboDidLogIn userID = %@ accesstoken = %@ expirationDate = %@ refresh_token = %@", sinaweibo.userID, sinaweibo.accessToken, sinaweibo.expirationDate,sinaweibo.refreshToken);
    
    [self sinaWeiboStoreAuthData];
}

- (void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboDidLogOut");
    [self sinaWeiboRemoveAuthData];
    
    [self logOutSuccess:sinaWeibo];
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo
{
    NSLog(@"sinaweiboLogInDidCancel");
    [self loginFail];
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error
{
    NSLog(@"sinaweibo logInDidFailWithError %@", error);
    [self loginFail];
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error
{
    NSLog(@"sinaweiboAccessTokenInvalidOrExpired %@", error);
    [self sinaWeiboRemoveAuthData];
    [self loginFail];
}

#pragma mark - SinaWeiboRequest Delegate

- (void)request:(SinaWeiboRequest *)request didFailWithError:(NSError *)error
{
    [self weiboSendFail:nil];
//    if ([request.url hasSuffix:@"statuses/update.json"])
//    {
//        [self weiboSendFail:error];
//        NSLog(@"Post status failed with error : %@", error);
//    }
//    else if ([request.url hasSuffix:@"statuses/upload.json"])
//    {
//        [self weiboSendFail:(NSError *)error];
//        NSLog(@"Post image status failed with error : %@", error);
//    }
}

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)result
{
    if ([request.url hasSuffix:@"statuses/update.json"])
    {
        if ([result objectForKey:@"error_code"])
        {
            [self weiboSendFail:nil];
        }
        else
        {
            [self weiboSendSuccess];
        }
    }
    else if ([request.url hasSuffix:@"statuses/upload.json"])
    {
        [self weiboSendSuccess];
    }
}

/*🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹🌹*/
#pragma mark - wechat delegate


-(BOOL)checkIsInstallWechat{
    if([WXApi isWXAppInstalled])return YES;
    [self showAlertView:^{
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"系统提示" message:@"你尚未安装微信客户端,确定安装吗？" delegate:self cancelButtonTitle:@"暂不" otherButtonTitles:@"确定", nil];
        alertView.tag = WeChatClientTag;
        return alertView;
    }()];
    return NO;
}


//send text 2 firend
- (void)sendWeChatPostMessage:(NSString*)message{
    if([self checkIsInstallWechat])
    [self weChatSendMessage:message andScene:WXSceneSession];
}



//send text 2 firend circle
- (void)sendWeChatFriendPostMessage:(NSString*)message{
    if([self checkIsInstallWechat])
    [self weChatSendMessage:message andScene:WXSceneTimeline];
}
-(void)weChatSendMessage:(NSString *)message andScene:(int)scene{
    if(![self checkIsInstallWechat])return;
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = YES;
    req.text = message;
    req.scene = scene;
    [WXApi sendReq:req];
}
- (void)sendWeChatContentTitle:(NSString *)title WithMessage:(NSString*)appMessage WithUrl:(NSString*)appUrl image:(UIImage *)image WithScene:(int)scene{
    // 发送内容给微信
    if(![self checkIsInstallWechat])return;
    
    NSString *sendTitle = scene == WXSceneSession ? title : appMessage;
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = sendTitle;
    message.description = appMessage;
    [message setThumbImage:image];
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = appUrl;
    
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [WXApi sendReq:req];
}

-(void) onSentTextMessage:(BOOL) bSent{
    bSent ? [self weiboSendSuccess] : [self weiboSendFail:nil];
}



//微信反馈
-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        if (0 == resp.errCode)
        {
            [self weiboSendSuccess];
        }
        else
        {
            [self weiboSendFail:nil];
        }
    }
}
/*🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂🍂*/
//tc weibo method
- (void)tcWeiboRemoveAuthData
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TcWeiboAuthData"];
}

- (void)tcWeiboStoreAuthData
{
    NSDictionary *authData = [NSDictionary dictionaryWithObjectsAndKeys:
                              tcWeiboEngine.accessToken, AccessTokenKey,
                              [NSString stringWithFormat:@"%lf", tcWeiboEngine.expireTime], ExpireTimeKey,
                              tcWeiboEngine.openId, OpenIdKey,
                              tcWeiboEngine.openKey, OpenKeyKey,
                              tcWeiboEngine.name, NameKey,
                              tcWeiboEngine.refreshToken, RefreshTokenKey,
                              [NSString stringWithFormat:@"%c", tcWeiboEngine.isSSOAuth], SSOAuthKey,nil];
    [[NSUserDefaults standardUserDefaults] setObject:authData forKey:@"TcWeiboAuthData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (shareEngineDidLogIn){
        shareEngineDidLogIn(tcWeibo,authData);
//      看是否还有之前因为没有登录导致没分享出去的内容，如果还有登录后就继续分享。
        if(recordUnLoginActionInfo){
            UIImage *image = recordUnLoginActionInfo[@"image"];
            NSString *mergeMessage = recordUnLoginActionInfo[@"message"];
            image ? [self tcWeiboSendImageAndUrlWithMessage:mergeMessage image:image] : [self tcWeiboSendTextWithMessage:mergeMessage];
            recordUnLoginActionInfo = nil;
        }
    }
    
}

- (void)tcWeiboReadAuthData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *tcweiboInfo = [defaults objectForKey:@"TcWeiboAuthData"];
    if ([tcweiboInfo objectForKey:AccessTokenKey] && [tcweiboInfo objectForKey:ExpireTimeKey] && [tcweiboInfo objectForKey:OpenIdKey] && [tcweiboInfo objectForKey:OpenKeyKey] &&
        [tcweiboInfo objectForKey:NameKey] && [tcweiboInfo objectForKey:OpenKeyKey]){
        tcWeiboEngine.accessToken = [tcweiboInfo objectForKey:AccessTokenKey];
        tcWeiboEngine.expireTime = [[tcweiboInfo objectForKey:ExpireTimeKey] doubleValue];
        tcWeiboEngine.openId = [tcweiboInfo objectForKey:OpenIdKey];
        tcWeiboEngine.openKey = [tcweiboInfo objectForKey:OpenKeyKey];
        tcWeiboEngine.name = [tcweiboInfo objectForKey:NameKey];
        tcWeiboEngine.refreshToken = [tcweiboInfo objectForKey:RefreshTokenKey];
        NSString *SSOAuth =  [tcweiboInfo objectForKey:SSOAuthKey];
        tcWeiboEngine.isSSOAuth = [SSOAuth isEqualToString:@"YES"]?YES:NO;
        if ([tcWeiboEngine.accessToken length] > 0) {
            tcWeiboEngine.isRefreshTokenSuccess = YES;
        }
    }
}


//腾讯微博登陆
-(void)tcWeiboLogin{
    
    
    [tcWeiboEngine logInWithDelegate:self onSuccess:@selector(onSuccessLogin) onFailure:@selector(onFailureLogin:)];
}
//登录成功回调
- (void)onSuccessLogin{
    
    
    
    [self tcWeiboStoreAuthData];
}

//登录失败回调
- (void)onFailureLogin:(NSError *)error
{
    [self loginFail];
}

- (void)onAccessTokenExpired{
    [self tcWeiboRemoveAuthData];
    [self loginFail];
}

- (void)onLoginOut
{
    [self tcWeiboRemoveAuthData];
    [self logOutSuccess:tcWeibo];
}



#pragma mark tencentweibo share
//腾讯微博图（data）文
-(void)tcWeiboSendImageAndUrlWithMessage:(NSString *)message image:(UIImage *)image{
    [tcWeiboEngine postPictureTweetWithFormat:@"json" content:message clientIP:nil pic:UIImageJPEGRepresentation(image, 1) compatibleFlag:nil longitude:nil andLatitude:nil parReserved:nil delegate:self onSuccess:@selector(createSuccess:) onFailure:@selector(createFail:)];
    
}
//腾讯微博图（url）文
-(void)tcWeiboSendImageurlAndUrlWithMessage:(NSString *)message pic:(NSString *)picUrl{
    [tcWeiboEngine postPictureURLTweetWithFormat:@"json" content:message clientIP:nil picURL:picUrl compatibleFlag:nil longitude:nil andLatitude:nil parReserved:nil delegate:self onSuccess:@selector(createSuccess:) onFailure:@selector(createFail:)];
}
//发送文本
-(void)tcWeiboSendTextWithMessage:(NSString *)message{

    [tcWeiboEngine postTextTweetWithFormat:@"json" content:message clientIP:nil longitude:nil andLatitude:nil parReserved:nil delegate:self onSuccess:@selector(createSuccess:) onFailure:@selector(createFail:)];
}

//微博登陆
-(void)onLoginSuccessed:(NSString *)name token:(WBToken *)token
{
    [self tcWeiboStoreAuthData];
}

-(void)onLoginFailed:(WBErrCode)errCode msg:(NSString *)msg
{
    [self weiboSendFail:nil];
}




#pragma mark common send result
- (void)createSuccess:(NSDictionary *)dict {
    NSLog(@"%s %@", __FUNCTION__,dict);
    if ([[dict objectForKey:@"ret"] intValue] == 0)
    {
        [self weiboSendSuccess];
        NSLog(@"发送成功！");
    }
    else
    {
        [self weiboSendFail:nil];
        NSLog(@"发送失败！");
    }
}

- (void)createFail:(NSError *)error
{
    [self weiboSendFail:error];
    NSLog(@"发送失败!error is %@",error);
}



//common alertview
-(void)showAlertView:(UIAlertView *)alertView{
    if(alertView)
        [alertView show];
}
@end
