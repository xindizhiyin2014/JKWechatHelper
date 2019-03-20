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
+ (instancetype)shareInstance;

/**
 初始化微信sdk

 @param model 0:正式环境 1:开发环境 2:体验环境  会涉及到小程序开发、体验、正式版本的切换
 @param appId 微信开发平台注册的appID
 */
+ (void)configModel:(NSInteger)model appId:(NSString *)appId;

+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 微信登录
 
 @param success 成功回调 data：code（string）
 @param failure 失败回调
 */
+ (void)wxLoginSuccess:(wxSuccessBlock)success
               failure:(wxFailureBlock)failure;

/**
 微信充值
 
 @param params 参数
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxPayWithParams:(NSDictionary *)params
                success:(wxSuccessBlock)success
                failure:(wxFailureBlock)failure;



/**
 微信拉取小程序
 
 @param params 参数
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxLaunchMiniProgramWithParams:(NSDictionary *)params
                              success:(wxSuccessBlock)success
                              failure:(wxFailureBlock)failure;


/**
 微信小程序分享
 
 @param params 参数
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareMiniProgramWithParams:(NSDictionary *)params
                             success:(wxSuccessBlock)success
                             failure:(wxFailureBlock)failure;

+ (void)weixinShareImage:(NSURL *)url extra:(NSDictionary *)extra complete:(void(id result,NSError *error))completeBlock;
/**
 微信图片分享
 
 @param params 参数
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareImageWithParams:(NSDictionary *)params
                       success:(wxSuccessBlock)success
                       failure:(wxFailureBlock)failure;



/**
 微信分享
 
 @param type 分享类型 0:图片，1:网页 2:小程序
 @param platform 平台 0:好友，1:朋友圈
 @param params 分享参数
 @param success 成功回调
 @param failure 失败回调
 */
+ (void)wxShareWithType:(NSInteger)type
               platform:(NSInteger)platform
                 params:(NSDictionary *)params
                success:(wxSuccessBlock)success
                failure:(wxFailureBlock)failure;
@end

NS_ASSUME_NONNULL_END
