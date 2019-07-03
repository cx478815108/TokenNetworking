//
//  TokenNetworking.h
//  NewHybrid
//
//  Created by 陈雄&武嘉晟 on 2018/6/11.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TokenHTTPBodyStream.h"
#import "TokenNetworkingAssistant.h"

NS_ASSUME_NONNULL_BEGIN

@class TokenNetworking;
@class TokenNetMicroTask;

// redirect 参数 BLOCK 定义
typedef NSURLRequest *_Nonnull(^TokenChainRedirectParameterBlock)(NSURLRequest *request, NSURLResponse *response);

/// 链式重定向 BLOCK 定义
typedef TokenNetMicroTask *_Nonnull(^TokenChainRedirectBlock)(TokenChainRedirectParameterBlock redirectParameter);

/// DATA JSON TEXT FAILURE 参数 BLOCK 定义
typedef void(^TokenNetSuccessDataBlock)(NSURLSessionTask *task, NSData *responseData);
typedef void(^TokenNetSuccessJSONBlock)(NSURLSessionTask *task, NSError *jsonError, id responsedObj);
typedef void(^TokenNetSuccessTextBlock)(NSURLSessionTask *task, NSString *responsedText);
typedef void(^TokenNetFailureParameterBlock)(NSError *error);

/// 链式 response 和 failure BLOCK 定义
typedef TokenNetMicroTask *_Nonnull(^TokenResponseDataBlock)(TokenNetSuccessDataBlock jsonBlock);
typedef TokenNetMicroTask *_Nonnull(^TokenResponseJSONBlock)(TokenNetSuccessJSONBlock jsonBlock);
typedef TokenNetMicroTask *_Nonnull(^TokenResponseTextBlock)(TokenNetSuccessTextBlock textBlock);
typedef TokenNetMicroTask *_Nonnull(^TokenNetFailureBlock)(TokenNetFailureParameterBlock failure);
typedef TokenNetMicroTask *_Nonnull(^TokenRetryCountBlock)(NSUInteger retryCount);

typedef TokenNetworking *_Nonnull(^TokenNetworkingCreateBlock)(NSURLSessionConfiguration *sessionConfiguration, NSOperationQueue *delegateQueue);
typedef TokenNetworking *_Nullable(^TokenNetworkingTasksBlock)(NSArray <TokenNetMicroTask *> *tasks, dispatch_block_t finish);

/// send block 定义
typedef NSURLRequest *_Nonnull(^TokenRequestMakeBlock)(void);

typedef TokenNetMicroTask *_Nonnull(^TokenSendRequestBlock)(TokenRequestMakeBlock make);
typedef TokenNetMicroTask *_Nonnull(^TokenNetRequestBlock)(NSURLRequest *request);
typedef TokenNetMicroTask *_Nonnull(^TokenNetParametersBlock)(NSString *urlString, NSDictionary *_Nullable parameters);

@interface TokenNetMicroTask : NSObject

@property (nonatomic, copy, readonly) TokenChainRedirectBlock redirect;
@property (nonatomic, copy, readonly) TokenResponseDataBlock  responseData;
@property (nonatomic, copy, readonly) TokenResponseTextBlock  responseText;
@property (nonatomic, copy, readonly) TokenResponseJSONBlock  responseJSON;
@property (nonatomic, copy, readonly) TokenNetFailureBlock    failure;
/// 执行 .next 之后返回 TokenNetworking 对象，可以进行新请求的发送
@property (nonatomic, weak, readonly) TokenNetworking *next;
/// 设置重试次数 只可以为 1 2 3
@property (nonatomic, assign, readonly) TokenRetryCountBlock retryCount;

@end

@interface TokenNetworking : NSObject

/// 此 block 可指定 NSURLSessionConfiguration 和 NSOperationQueue
@property (nonatomic, readonly, class) TokenNetworkingCreateBlock createNetworking;
@property (nonatomic, readonly, class) TokenNetworking *networking;
@property (nonatomic, readonly, class) TokenNetworkingTasksBlock allTasks;

/// 以下 block 执行后返回 TokenNetMicroTask 对象，可以进行返回数据处理和重定向相关工作
@property (nonatomic, copy, readonly) TokenSendRequestBlock   makeRequest;
@property (nonatomic, copy, readonly) TokenNetRequestBlock    requestWith;
@property (nonatomic, copy, readonly) TokenNetParametersBlock getWithURL;
@property (nonatomic, copy, readonly) TokenNetParametersBlock postWithURL;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
