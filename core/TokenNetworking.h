//
//  TokenNetworking.h
//  NewHybrid
//
//  Created by 陈雄&武嘉晟 on 2018/6/11.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TokenNetworkingCategories.h"

@class TokenNetworking;


typedef TokenNetworking *(^TokenNetworkingCreateBlock)(NSURLSessionConfiguration *sessionConfiguration, NSOperationQueue *delegateQueue);

//send
typedef NSURLRequest    *(^TokenRequestMakeBlock)(void);
typedef TokenNetworking *(^TokenSendRequestBlock)(TokenRequestMakeBlock make);
typedef TokenNetworking *(^TokenNetParametersBlock)(NSString *urlString, NSDictionary *parameters);

//redirect
typedef NSURLRequest    *(^TokenChainRedirectParameterBlock)(NSURLRequest *request, NSURLResponse *response);
typedef TokenNetworking *(^TokenChainRedirectBlock)(TokenChainRedirectParameterBlock redirectParameter);

//JSON TEXT FAILURE参数BLOCK
typedef void(^TokenNetSuccessJSONBlock)(NSURLSessionTask *task, NSError *jsonError, id responsedObj);
typedef void(^TokenNetSuccessTextBlock)(NSURLSessionTask *task, NSString *responsedText);
typedef void(^TokenNetFailureParameterBlock)(NSError *error);

//response
typedef TokenNetworking *(^TokenResponseJSONBlock)(TokenNetSuccessJSONBlock jsonBlock);
typedef TokenNetworking *(^TokenResponseTextBlock)(TokenNetSuccessTextBlock textBlock);

//willFailure
typedef TokenNetworking *(^TokenWillFailureBlock)(TokenNetFailureParameterBlock failureBlock);

//失败BLOCK
typedef TokenNetworking *(^TokenNetFailureBlock)(TokenNetFailureParameterBlock failure);

@interface TokenNetworking : NSObject

- (instancetype)init NS_UNAVAILABLE;

//初始化方法
+ (instancetype)networking;
@end

@interface TokenNetworking(Chain)

@property (nonatomic, readonly, class) TokenNetworkingCreateBlock createNetworking;

//链式调用的基础
@property (nonatomic, copy, readonly) TokenNetParametersBlock getWithURL;
@property (nonatomic, copy, readonly) TokenNetParametersBlock postWithURL;
@property (nonatomic, copy, readonly) TokenSendRequestBlock   request;
@property (nonatomic, copy, readonly) TokenChainRedirectBlock willRedirect;
@property (nonatomic, copy, readonly) TokenResponseJSONBlock  willResponseJSON;
@property (nonatomic, copy, readonly) TokenResponseTextBlock  willResponseText;
@property (nonatomic, copy, readonly) TokenResponseJSONBlock  responseJSON;
@property (nonatomic, copy, readonly) TokenResponseTextBlock  responseText;
@property (nonatomic, copy, readonly) TokenWillFailureBlock   willFailure;
@property (nonatomic, copy, readonly) TokenNetFailureBlock    failure;

@end
