//
//  JKWechatHelper.h
//  Pods
//
//  Created by JackLee on 2019/3/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^wxSuccessBlock)(id data);
typedef void(^wxFailureBlock)(NSError *error);

@interface JKWechatHelper : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)shareInstance;

/**
 初始化微信sdk

 @param model 0:开发环境 1:正式环境 开发环境会涉及到日志的打印
 @param appId 微信开发平台注册的appID
 */
+ (void)configModel:(NSInteger)model appId:(NSString *)appId;

/**
 处理app跨应用跳转，主要在AppDelegate中应用

 @param url 跳转的url
 @return 处理结果
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 微信登录
 
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxLoginSuccess:(wxSuccessBlock)success
               failure:(wxFailureBlock)failure;

/**
 微信充值
 
 @param params 参数如:
 
 @"appid" : 由用户微信号和AppID组成的唯一标识，发送请求时第三方程序必须填写，用于校验微信用户是否换号登录
 @"partnerid" : 商家向财付通申请的商家id
 @"prepayid" : 预支付订单id
 @"noncestr" : 随机串，防重发
 @"timestamp" : 时间戳，防重发
 @"package" : 商家根据财付通文档填写的数据和签名
 @"sign" : 商家根据微信开放平台文档对数据做的签名
 
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxPayWithParams:(NSDictionary *)params
                success:(wxSuccessBlock)success
                failure:(wxFailureBlock)failure;

/**
 微信拉取小程序
 
 @param params 参数如下:
 
 @"userName" : 小程序username
 @"type" : 0:小程序正式版， 1:小程序开发版，2:小程序体验版
 @"path" : 小程序页面的路径,不填默认拉起小程序首页
 
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxLaunchMiniProgramWithParams:(NSDictionary *)params
                              success:(wxSuccessBlock)success
                              failure:(wxFailureBlock)failure;
//参数拼接在url中同上一个方法
+ (void)wxLaunchMiniProgramWithURL:(NSURL *)url
                           success:(wxSuccessBlock)success
                           failure:(wxFailureBlock)failure;



/**
 微信小程序分享
 
 @param params 参数如下:
 
 @"userName" : 小程序username
 @"type" : 0:小程序正式版， 1:小程序开发版，2:小程序体验版
 @"path" : 小程序页面的路径,不填默认拉起小程序首页
 @"title" : 分享的标题
 @ "webpageUrl" : 低版本网页链接,长度不能超过1024字节
 @"image" : 小程序新版本的预览图,大小不能超过128k
 @"scene": 发送的目标场景，0: 聊天会话界面, 1: 朋友圈, 2: 收藏, 3: 指定联系人 默认发送到会话。
 
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareMiniProgramWithParams:(NSDictionary *)params
                             success:(wxSuccessBlock)success
                             failure:(wxFailureBlock)failure;

/**
 微信分享图片,具体参数配置参考下面的方法

 @param url url
 @param extra 额外的参数
 @param completeBlock 完成回调
 */
+ (void)wxShareImage:(NSURL *)url extra:(NSDictionary *)extra complete:(void(^)(id result,NSError *error))completeBlock;
/**
 微信图片分享
 
 @param params 参数如下:
 @"image" : 要分享的图片
 @"scene": 分享的目标场景, 0: 聊天会话界面, 1: 朋友圈, 2: 收藏, 3: 指定联系人 默认发送到会话。
 
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareImageWithParams:(NSDictionary *)params
                       success:(wxSuccessBlock)success
                       failure:(wxFailureBlock)failure;

/**
 微信网页分享

 @param params 参数如下:
 @"title" : 标题,长度不能超过512字节
 @"desc" : 描述内容,长度不能超过1K
 @"url" : 网页的url地址,不能为空且长度不能超过10K
 @"scene" : 分享的目标场景, 0: 聊天会话界面, 1: 朋友圈, 2: 收藏, 3: 指定联系人 默认发送到会话。
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareUrlWithParams:(NSDictionary *)params
                     success:(wxSuccessBlock)success
                     failure:(wxFailureBlock)failure;
/**
 微信分享
 
 @param shareType 分享类型 0:图片，1:网页 2:小程序
 @param params 分享参数 具体参数根据对应的分享类型参考上面的方法
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareWithType:(NSInteger)shareType
                 params:(NSDictionary *)params
                success:(wxSuccessBlock)success
                failure:(wxFailureBlock)failure;
@end

NS_ASSUME_NONNULL_END
