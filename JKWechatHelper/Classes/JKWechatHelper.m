//
//  JKWechatHelper.m
//  Pods
//
//  Created by JackLee on 2019/3/20.
//
#ifdef DEBUG
#define JKLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define JKLog(...)
#endif
static inline NSError * errorBuild(NSInteger errorCode, NSString *domain, NSString *errorMsg){
    NSMutableDictionary *useinfo = [NSMutableDictionary dictionary];
    if (errorMsg) {
        [useinfo setObject:errorMsg forKey:NSLocalizedDescriptionKey];
    }
    NSError *error = [[NSError alloc] initWithDomain:domain code:errorCode userInfo:useinfo];
    return error;
}

static NSString * const JKWeiXinErrorDomain = @"JKWeiXinAPIErrorDomain"; // 微信api错误


#import "JKWechatHelper.h"
#import <WechatOpenSDK/WXApi.h>
#import <JKDataHelper/JKDataHelperMacro.h>

@interface JKWechatHelper()<WXApiLogDelegate,WXApiDelegate>
@property (nonatomic, copy) wxSuccessBlock successBlock;
@property (nonatomic, copy) wxFailureBlock failureBlock;
@property (nonatomic, strong) NSString *authStateStr;
@property (nonatomic, assign) NSInteger configModel;
@end

@implementation JKWechatHelper
static JKWechatHelper *_helper = nil;
+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = [JKWechatHelper new];
    });
    return _helper;
}

+ (void)configModel:(NSInteger)model appId:(NSString *)appId{
    [WXApi registerApp:appId enableMTA:NO];
    [JKWechatHelper shareInstance].configModel = model;
    if (model != 0) {
        [WXApi startLogByLevel:WXLogLevelDetail logDelegate:[JKWechatHelper shareInstance]];
    }
}

+ (BOOL)handleOpenURL:(NSURL *)url{
   return [WXApi handleOpenURL:url delegate:[JKWechatHelper shareInstance]];
}

#pragma mark - - - - WXApiLogDelegate - - - -

- (void)onLog:(NSString *)log logLevel:(WXLogLevel)level{
    JKLog(@"微信SKD日志：%@  %@", log, @(level));
}

+ (void)clearBlock{
    [JKWechatHelper shareInstance].successBlock = nil;
    [JKWechatHelper shareInstance].failureBlock = nil;
}

+ (NSString *)requestStateString{
    NSString *stateString = [JKWechatHelper randomStringWithLength:8];
    [JKWechatHelper shareInstance].authStateStr = stateString;
    return stateString;
}

+ (void)wxLoginSuccess:(wxSuccessBlock)success failure:(wxFailureBlock)failure{
    [JKWechatHelper shareInstance].successBlock = success;
    [JKWechatHelper shareInstance].failureBlock = failure;
    
    if (![WXApi isWXAppInstalled]) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"还未安装微信哦");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    
    SendAuthReq* req = [[SendAuthReq alloc ] init];
    req.scope = @"snsapi_userinfo";
    req.state = [self requestStateString];
    BOOL result = [WXApi sendReq:req];
    if (!result) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"无法使用微信登录");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
    }
}


+ (void)wxPayWithParams:(NSDictionary *)params success:(wxSuccessBlock)success failure:(wxFailureBlock)failure{
    [JKWechatHelper shareInstance].successBlock = success;
    [JKWechatHelper shareInstance].failureBlock = failure;
    
    if (![WXApi isWXAppInstalled]) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"还未安装微信哦");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    
    //调起微信支付
    PayReq* req = [[PayReq alloc] init];
    req.openID      = [params objectForKey:@"appid"];
    req.partnerId   = [params objectForKey:@"partnerid"];
    req.prepayId    = [params objectForKey:@"prepayid"];
    req.nonceStr    = [params objectForKey:@"noncestr"];
    req.timeStamp   = [[params objectForKey:@"timestamp"] intValue];
    req.package     = [params objectForKey:@"package"];
    req.sign        = [params objectForKey:@"sign"];
    
    if (!req.package) {
        req.package = @"Sign=WXPay";
    }
    
    
    BOOL result = [WXApi sendReq:req];
    if (!result) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"微信支付失败");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
    }
}


+ (void)wxLaunchMiniProgramWithParams:(NSDictionary *)params success:(wxSuccessBlock)success failure:(wxFailureBlock)failure{
    [JKWechatHelper shareInstance].successBlock = success;
    [JKWechatHelper shareInstance].failureBlock = failure;
    
    if (![WXApi isWXAppInstalled]) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"还未安装微信哦");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    
    NSMutableDictionary *mParams = [NSMutableDictionary dictionaryWithDictionary:params];
    
    NSString *userName = [mParams objectForKey:@"userName"];
    if (JKIsEmptyStr(userName)) {
       NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"小程序id为空");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    [mParams removeObjectForKey:@"userName"];
    WXMiniProgramType miniProgramTypetype = [JKWechatHelper shareInstance].configModel?WXMiniProgramTypePreview:WXMiniProgramTypeRelease;
    
    if ([mParams jk_containKey:@"type"]) {
        NSInteger type = [[mParams objectForKey:@"type"] integerValue];
        if (type>=0 && type <=2) {
            miniProgramTypetype = type;
        }
    }
    [mParams removeObjectForKey:@"type"];
    
    __block NSString *path = [mParams objectForKey:@"path"];
    [mParams removeObjectForKey:@"path"];
    
    if (!JKIsEmptyStr(path) && mParams.count > 0) {
        __block NSInteger index = 0;
        [mParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                if (index == 0) {
                    path = [path stringByAppendingFormat:@"?%@=%@", key, obj];
                }else{
                    path = [path stringByAppendingFormat:@"&%@=%@", key, obj];
                }
                index ++;
            }
        }];
    }
    
    
    WXLaunchMiniProgramReq *launchMiniProgramReq = [WXLaunchMiniProgramReq object];
    launchMiniProgramReq.userName = userName;  //拉起的小程序的username
    if (!JKIsEmptyStr(path)) {
        launchMiniProgramReq.path = path;    //拉起小程序页面的可带参路径，不填默认拉起小程序首页
    }
    launchMiniProgramReq.miniProgramType = miniProgramTypetype; //拉起小程序的类型
    BOOL result = [WXApi sendReq:launchMiniProgramReq];
    if (!result) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"微信小程序唤起失败");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
    }
}


+ (void)wxShareMiniProgramWithParams:(NSDictionary *)params success:(wxSuccessBlock)success failure:(wxFailureBlock)failure{
    [JKWechatHelper shareInstance].successBlock = success;
    [JKWechatHelper shareInstance].failureBlock = failure;
    
    if (![WXApi isWXAppInstalled]) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"还未安装微信哦");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    
    NSMutableDictionary *mParams = [NSMutableDictionary dictionaryWithDictionary:params];
    
    NSString *userName = [mParams objectForKey:@"userName"];
    if (JKIsEmptyStr(userName)) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"小程序id为空");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    [mParams removeObjectForKey:@"userName"];
    
    WXMiniProgramType miniProgramTypetype = [JKWechatHelper shareInstance].configModel?WXMiniProgramTypePreview:WXMiniProgramTypeRelease;
    
    if ([mParams jk_containKey:@"type"]) {
        NSInteger type = [[mParams objectForKey:@"type"] integerValue];
        if (type>=0 && type <=2) {
            miniProgramTypetype = type;
        }
    }
    [mParams removeObjectForKey:@"type"];
    
    int scene  = [[mParams objectForKey:@"scene"] intValue];
    [mParams removeObjectForKey:@"scene"];
    
    __block NSString *path = [mParams objectForKey:@"path"];
    [mParams removeObjectForKey:@"path"];
    
    if (!JKIsEmptyStr(path) && mParams.count > 0) {
        __block NSInteger index = 0;
        [mParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                if (index == 0) {
                    path = [path stringByAppendingFormat:@"?%@=%@", key, obj];
                }else{
                    path = [path stringByAppendingFormat:@"&%@=%@", key, obj];
                }
                index ++;
            }
            
        }];
    }
    
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = [mParams jk_stringForKey:@"title"];
    WXMiniProgramObject *wxMiniObejct = [WXMiniProgramObject object];
    wxMiniObejct.userName = userName;
    wxMiniObejct.path = path;
    wxMiniObejct.miniProgramType = miniProgramTypetype;
    wxMiniObejct.webpageUrl =  [mParams jk_stringForKey:@"webpageUrl"];
    
    UIImage *image = (UIImage *)[params objectForKey:@"image"];
    wxMiniObejct.hdImageData = UIImageJPEGRepresentation(image, 0.3);
    
    
    message.mediaObject = wxMiniObejct;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.message = message;
    req.bText = NO;
    req.scene = scene;
    
    
    BOOL result = [WXApi sendReq:req];
    if (!result) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"分享失败");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
    }
}

+ (void)weixinShareImage:(NSURL *)url extra:(NSDictionary *)extra complete:(void(id result,NSError *error))completeBlock{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:[url.query jk_URLQueryDictionary]];
    if (extra) {
        [params addEntriesFromDictionary:extra];
    }
    
    [self wxShareImageWithParams:params success:^(id data) {
        if (completeBlock) {
            completeBlock(data, nil);
        }
    } failure:^(NSError *error) {
        if (completeBlock) {
            completeBlock(nil, error);
        }
    }];
}

+ (void)wxShareImageWithParams:(NSDictionary *)params success:(wxSuccessBlock)success failure:(wxFailureBlock)failure{
    [JKWechatHelper shareInstance].successBlock = success;
    [JKWechatHelper shareInstance].failureBlock = failure;
    
    if (![WXApi isWXAppInstalled]) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"还未安装微信哦");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    
    int scene  = [[params objectForKey:@"scene"] intValue];
    
    WXMediaMessage *message = [WXMediaMessage message];
    
    WXImageObject *imgObject  = [WXImageObject object];
    UIImage *image = (UIImage *)[params objectForKey:@"image"];
    imgObject.imageData = UIImagePNGRepresentation(image);
    message.mediaObject = imgObject;
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.message = message;
    req.bText = NO;
    req.scene = scene;
    
    BOOL result = [WXApi sendReq:req];
    if (!result) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"分享失败");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
    }
    
}

+ (void)wxShareWithType:(NSInteger)type platform:(NSInteger)platform params:(NSDictionary *)params success:(wxSuccessBlock)success failure:(wxFailureBlock)failure{
    
    [JKWechatHelper shareInstance].successBlock = success;
    [JKWechatHelper shareInstance].failureBlock = failure;
    
    if (![WXApi isWXAppInstalled]) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"还未安装微信哦");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
        return;
    }
    WXMediaMessage *message = [WXMediaMessage message];
    if (type ==0) {//图片分享
        WXImageObject *imgObject  = [WXImageObject object];
        UIImage *image = (UIImage *)[params objectForKey:@"image"];
        imgObject.imageData = UIImagePNGRepresentation(image);
        message.mediaObject = imgObject;
    }else if (type ==1){//网页分享
        message.title = [params jk_stringForKey:@"title"];
        message.description = [params jk_stringForKey:@"desc"];
        WXWebpageObject *webpageObject = [WXWebpageObject object];
        webpageObject.webpageUrl = [params jk_stringForKey:@"url"];
    }else if (type == 2){//小程序分享
        WXMiniProgramObject *wxMiniObejct = [WXMiniProgramObject object];
        wxMiniObejct.userName = [params jk_stringForKey:@"userName"];
        wxMiniObejct.path = [params jk_stringForKey:@"path"];
        
        UIImage *image = (UIImage *)[params objectForKey:@"image"];
        wxMiniObejct.hdImageData = UIImagePNGRepresentation(image);
        
        message.title = [params jk_stringForKey:@"title"];
        message.description = [params jk_stringForKey:@"desc"];
        message.mediaObject = wxMiniObejct;
        message.thumbData = nil;
    }
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.message = message;
    if (platform ==0) {//分享给好友
        req.bText = NO;
        req.scene = WXSceneSession;
    }else if (platform ==1){//分享到朋友圈
        req.bText = NO;
        req.scene = WXSceneTimeline;
    }
    BOOL result = [WXApi sendReq:req];
    if (!result) {
        NSError *error = errorBuild(-100, JKWeiXinErrorDomain, @"微信小程序唤起失败");
        if ([JKWechatHelper shareInstance].failureBlock) {
            [JKWechatHelper shareInstance].failureBlock(error);
        }
        [self clearBlock];
    }
}


#pragma mark private method
+ (void)handleAuthRequest:(SendAuthResp *)resp{
    if ([resp.state isEqualToString:[JKWechatHelper shareInstance].authStateStr]){
        if (resp.errCode == WXSuccess) {
            if ([JKWechatHelper shareInstance].successBlock) {
                NSString *code = [NSString stringWithFormat:@"%@", resp.code];
                [JKWechatHelper shareInstance].successBlock(code);
            }
        }else{
            if ([JKWechatHelper shareInstance].failureBlock) {
                NSString *errorMsg = resp.errStr;
                if (resp.errCode == WXErrCodeUserCancel) {
                    errorMsg = @"微信登录取消";
                }
                NSError *error = errorBuild(resp.errCode, JKWeiXinErrorDomain, errorMsg);
                [JKWechatHelper shareInstance].failureBlock(error);
            }
        }
    }
    [self clearBlock];
}

+ (void)handlePayRequest:(PayResp *)resp{
    if (resp.errCode == WXSuccess) {
        if ([JKWechatHelper shareInstance].successBlock) {
            [JKWechatHelper shareInstance].successBlock(@"充值成功");
        }
    } else {
        if ([JKWechatHelper shareInstance].failureBlock) {
            NSString *errorMsg = resp.errStr;
            if (resp.errCode == WXErrCodeUserCancel) {
                errorMsg = @"微信支付取消";
            }
            
            NSError *error = errorBuild(resp.errCode, JKWeiXinErrorDomain, errorMsg);
            [JKWechatHelper shareInstance].failureBlock(error);
        }
    }
    [self clearBlock];
}


+ (void)handleLaunchMiniProgramResp:(WXLaunchMiniProgramResp *)resp{
    if (resp.errCode == WXSuccess) {
        NSString *string = resp.extMsg;
        if ([JKWechatHelper shareInstance].successBlock) {
            [JKWechatHelper shareInstance].successBlock(string);
        }
    } else {
        if ([JKWechatHelper shareInstance].failureBlock) {
            NSString *errorMsg = resp.errStr;
            if (resp.errCode == WXErrCodeUserCancel) {
                errorMsg = @"小程序返回取消";
            }
            
            NSError *error = errorBuild(resp.errCode, JKWeiXinErrorDomain, errorMsg);
            [JKWechatHelper shareInstance].failureBlock(error);
        }
    }
    [self clearBlock];
}

+ (void)handleSendMessageWithRep:(SendMessageToWXResp *)resp{
    if (resp.errCode == WXSuccess) {
        if ([JKWechatHelper shareInstance].successBlock) {
            [JKWechatHelper shareInstance].successBlock(@"分享成功");
        }
    }else{
        if ([JKWechatHelper shareInstance].failureBlock) {
            NSString *errorMsg = @"分享失败";
            if (resp.errCode == WXErrCodeUserCancel) {
                errorMsg = @"取消分享";
            }else if(resp.errCode == WXErrCodeSentFail){
                errorMsg = @"分享失败";
            }
            NSError *error = errorBuild(resp.errCode, JKWeiXinErrorDomain, errorMsg);
            [JKWechatHelper shareInstance].failureBlock(error);
        }
    }
    [self clearBlock];
}

#pragma mark - WXApiDelegate
+ (void)onResp:(BaseResp *)resp{
    if ([resp isKindOfClass:[SendAuthResp class]]) {
        [self handleAuthRequest:(SendAuthResp *)resp];
    }else if ([resp isKindOfClass:[PayResp class]]){
        [self handlePayRequest:(PayResp *)resp];
    }else if ([resp isKindOfClass:[WXLaunchMiniProgramResp class]]){
        [self handleLaunchMiniProgramResp:(WXLaunchMiniProgramResp *)resp];
    }else if ([resp isKindOfClass:[SendMessageToWXResp class]]){
        [self handleSendMessageWithRep:(SendMessageToWXResp *)resp];
    }
    else{
        
    }
}

+ (void)onReq:(BaseReq *)req{
    if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        if ([JKWechatHelper shareInstance].successBlock) {
            [JKWechatHelper shareInstance].successBlock(@"123213123");
        }
    }
}

+ (NSString *)randomStringWithLength:(NSUInteger)length{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i=0; i<length; i++) {
        NSUInteger index = arc4random_uniform((uint32_t)letters.length);
        
        [randomString appendFormat: @"%C", [letters characterAtIndex:index]];
    }
    
    return randomString;
}


@end
