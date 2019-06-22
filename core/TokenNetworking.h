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

// redirect
typedef NSURLRequest    *_Nonnull(^TokenChainRedirectParameterBlock)(NSURLRequest *request, NSURLResponse *response);
typedef TokenNetMicroTask *_Nonnull(^TokenChainRedirectBlock)(TokenChainRedirectParameterBlock redirectParameter);

// JSON TEXT FAILURE参数BLOCK
typedef void(^TokenNetSuccessJSONBlock)(NSURLSessionTask *task, NSError *jsonError, id responsedObj);
typedef void(^TokenNetSuccessTextBlock)(NSURLSessionTask *task, NSString *responsedText);
typedef void(^TokenNetSuccessDataBlock)(NSURLSessionTask *task, NSData *responseData);
typedef void(^TokenNetFailureParameterBlock)(NSError *error);

// response
typedef TokenNetMicroTask *_Nonnull(^TokenResponseDataBlock)(TokenNetSuccessDataBlock jsonBlock);
typedef TokenNetMicroTask *_Nonnull(^TokenResponseJSONBlock)(TokenNetSuccessJSONBlock jsonBlock);
typedef TokenNetMicroTask *_Nonnull(^TokenResponseTextBlock)(TokenNetSuccessTextBlock textBlock);
typedef TokenNetMicroTask *_Nonnull(^TokenNetFailureBlock)(TokenNetFailureParameterBlock failure);

typedef TokenNetworking *_Nullable(^TokenNetworkingTasksBlock)(NSArray <TokenNetMicroTask *> *tasks, dispatch_block_t finish);
typedef TokenNetworking *_Nonnull(^TokenNetworkingCreateBlock)(NSURLSessionConfiguration *sessionConfiguration, NSOperationQueue *delegateQueue);

// send
typedef NSURLRequest    *_Nonnull(^TokenRequestMakeBlock)(void);
typedef TokenNetMicroTask *_Nonnull(^TokenSendRequestBlock)(TokenRequestMakeBlock make);
typedef TokenNetMicroTask *_Nonnull(^TokenNetRequestBlock)(NSURLRequest *request);
typedef TokenNetMicroTask *_Nonnull(^TokenNetParametersBlock)(NSString *urlString, NSDictionary *_Nullable parameters);

@interface TokenNetMicroTask : NSObject
@property (nonatomic, copy, readonly) TokenChainRedirectBlock redirect;
@property (nonatomic, copy, readonly) TokenResponseDataBlock  responseData;
@property (nonatomic, copy, readonly) TokenResponseTextBlock  responseText;
@property (nonatomic, copy, readonly) TokenResponseJSONBlock  responseJSON;
@property (nonatomic, copy, readonly) TokenNetFailureBlock    failure;
@property (nonatomic, weak, readonly) TokenNetworking *next;
@end

@interface TokenNetworking : NSObject
@property (nonatomic, readonly, class) TokenNetworkingCreateBlock createNetworking;
@property (nonatomic, readonly, class) TokenNetworking *networking;
@property (nonatomic, readonly, class) TokenNetworkingTasksBlock allTasks;

@property (nonatomic, copy, readonly) TokenSendRequestBlock   makeRequest;
@property (nonatomic, copy, readonly) TokenNetRequestBlock    requestWith;
@property (nonatomic, copy, readonly) TokenNetParametersBlock getWithURL;
@property (nonatomic, copy, readonly) TokenNetParametersBlock postWithURL;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
