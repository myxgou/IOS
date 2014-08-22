//
//  ThirdAction.m
//  ThirdAction
//
//  Created by wac on 14-8-13.
//  Copyright (c) 2014年 com.myxgou.third. All rights reserved.
//




#import "ThirdAction.h"
#import "ShareEngine.h"
@implementation ThirdAction
@synthesize thirdActionDelegate,loginFailNotifyName,loginOutNotifyName,loginSucessNotifyName,shareFailNotifyName,shareSucessNotifyName;
+(ThirdAction*)instance{
    static dispatch_once_t onceToken;
    static ThirdAction *_self_once = nil;
    dispatch_once(&onceToken, ^{
        _self_once = [[ThirdAction alloc] init];
    });
    return _self_once;
}

-(void)registerActionsCollection{
    NSNotificationCenter *NotifyHandle = [NSNotificationCenter defaultCenter];
//        登录成功回调
    if(self.loginSucessNotifyName)
        [[ShareEngine sharedInstance] setShareEngineDidLogIn:^(PlatformType sign,NSDictionary *dictionary){
            
            [NotifyHandle postNotificationName:loginSucessNotifyName object:nil userInfo:@{@"sign":@(sign),@"data":dictionary}];
        }];
//      登录失败回调
    if(self.loginFailNotifyName)
        [[ShareEngine sharedInstance] setShareEngineLoginFail:^{
            [NotifyHandle postNotificationName:loginFailNotifyName object:nil userInfo:nil];
        }];
//      退出登录回调
    if(self.loginOutNotifyName)
        [[ShareEngine sharedInstance] setShareEngineDidLogOut:^(PlatformType sign){
            [NotifyHandle postNotificationName:loginOutNotifyName object:nil userInfo:nil];
        }];
//    分享成功
    if(self.shareSucessNotifyName)
        [[ShareEngine sharedInstance] setShareEngineSendSuccess:^{
            [NotifyHandle postNotificationName:shareSucessNotifyName object:nil userInfo:nil];
        }];
//        分享失败
    if(self.shareFailNotifyName)
        [[ShareEngine sharedInstance] setShareEngineSendFail:^{
           [NotifyHandle postNotificationName:shareFailNotifyName object:nil userInfo:nil];
        }];
}
-(void)rdyRegisterAllFlatform{
    [self registerQQClient];
    [self registerSinaWeiboClient];
    [self registerTCWeiboClient];
    [self registerWeChatClient];
}
-(BOOL)handleOpenURLWithUrl:(NSURL *)url{
    return [[ShareEngine sharedInstance] handleOpenURL:url];
}
//注册各平台
-(void)registerSinaWeiboClient{
    if(thirdActionDelegate && [thirdActionDelegate respondsToSelector:@selector(fillSinaInfo)]){
        NSDictionary *dictionary = [thirdActionDelegate performSelector:@selector(fillSinaInfo)];
        [[ShareEngine sharedInstance] registerAppBySign:sinaWeibo andKey:dictionary[@"appkey"] andSecret:dictionary[@"secret"] andRedirectURI:dictionary[@"redirect"]];
    }
}
-(void)registerTCWeiboClient{
    if(thirdActionDelegate && [thirdActionDelegate respondsToSelector:@selector(fillTencentInfo)]){
        NSDictionary *dictionary = [thirdActionDelegate performSelector:@selector(fillTencentInfo)];
        [[ShareEngine sharedInstance] registerAppBySign:tcWeibo andKey:dictionary[@"appkey"] andSecret:dictionary[@"secret"] andRedirectURI:dictionary[@"redirect"]];
    }
}
-(void)registerWeChatClient{
    if(thirdActionDelegate && [thirdActionDelegate respondsToSelector:@selector(fillWechatInfo)]){
        NSString *appkey = [thirdActionDelegate performSelector:@selector(fillWechatInfo)];
        [[ShareEngine sharedInstance] registerAppBySign:weChat andKey:appkey andSecret:nil andRedirectURI:nil];
    }
}
-(void)registerQQClient{
    if(thirdActionDelegate && [thirdActionDelegate respondsToSelector:@selector(fillQQInfo)]){
        NSString *appkey = [thirdActionDelegate performSelector:@selector(fillQQInfo)];
         NSLog(@"dictionary:%@",appkey);
        [[ShareEngine sharedInstance] registerAppBySign:qqClient andKey:appkey andSecret:nil andRedirectURI:nil];
    }
}


-(void)thirdLoginBySign:(PlatformType)sign{
    
    [[ShareEngine sharedInstance] loginWithType:sign];
}

-(void)thirdShareTextWithTitle:(NSString *)title andMessage:(NSString*)message andUrl:(NSString *)url WithType:(PlatformType)sign{
    [[ShareEngine sharedInstance] shareMediaWithTitle:title message:message WithType:sign,url,nil];
}
-(void)thirdShareMediaWithTitle:(NSString *)title andMessage:(NSString*)message andUrl:(NSString *)url andImage:(UIImage *)image  WithType:(PlatformType)sign{
    if(url)
        [[ShareEngine sharedInstance] shareMediaWithTitle:title message:message WithType:sign,url,image,nil];
    else
        [[ShareEngine sharedInstance] shareMediaWithTitle:title message:message WithType:sign,image,nil];
}

@end
