//
//  TokenNetworking.h
//  NewHybrid
//
//  Created by 陈雄 on 2018/6/11.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TokenNetworkingCategories.h"

/**
     NSString *loginURL = @"https://www.xxx.com";
     NSDictionary *parameter = @{
         @"userName":@"xxx",
         @"password":@"xxx"
     };
 
     TokenNetworking.networking
     .postWithURL(loginURL, parameter)
     .responseJSON(^(NSURLSessionTask *task, NSError *jsonError,id responsedObj) {
         if (jsonError) {
             NSLog(@"json parse error %@",jsonError);
         }
         if (responsedObj) {
             NSLog(@"json = %@",responsedObj);
         }
     })
 
     // or you can get Text at the same time
     .responseText(^(NSURLSessionTask *task, NSString *responsedText) {
        NSLog(@"responsedText = %@",responsedText);
     })
 
     // or you can send another request
     .postWithURL(loginURL1, parameter1)
     .responseJSON(^(NSURLSessionTask *task, NSError *jsonError,id responsedObj) {
        if (jsonError) {
            NSLog(@"json parse error %@",jsonError);
        }
        if (responsedObj) {
            NSLog(@"json = %@",responsedObj);
        }
     });
 
     //custom request
 
     //creat a Request
     NSURL *url = [NSURL URLWithString:@"http://www.xxx.com"];
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
     request.token_setMethod(@"POST")
     .token_setTimeout(30);
 
    //send the Request
     TokenNetworking.networking
     .request(^NSURLRequest *{
         return request;
     })
     .responseText(^(NSURLSessionTask *task, NSString *responsedText) {
         NSLog(@"%@",responsedText);
     })
     .responseJSON(^(NSURLSessionTask *task, NSError *jsonError,id responsedObj) {
         if (jsonError) {
             NSLog(@"json parse error %@",jsonError);
         }
         if (responsedObj) {
             NSLog(@"json = %@",responsedObj);
         }
     });
 */
@class TokenNetworking;

//result
typedef void(^TokenNetSuccessJSONBlock)(NSURLSessionTask *task,NSError *jsonError,id responsedObj);
typedef void(^TokenNetSuccessTextBlock)(NSURLSessionTask *task,NSString *responsedText);
typedef void(^TokenNetFailureParameterBlock)(NSError *error);
typedef TokenNetworking *(^TokenNetFailureBlock)(TokenNetFailureParameterBlock failure);

//send
typedef TokenNetworking *(^TokenNetURLBlock)(NSString *urlString);
typedef NSURLRequest    *(^TokenRequestMakeBlock)(void);
typedef TokenNetworking *(^TokenSendRequestBlock)(TokenRequestMakeBlock make);
typedef TokenNetworking *(^TokenNetParametersBlock)(NSString *urlString,NSDictionary *parameters);

//redirect
typedef NSURLRequest    *(^TokenChainRedirectParameterBlock)(NSURLRequest *request,NSURLResponse *response);
typedef TokenNetworking *(^TokenChainRedirectBlock)(TokenChainRedirectParameterBlock redirectParameter);

//response
typedef TokenNetworking *(^TokenResponseJSONBlock)(TokenNetSuccessJSONBlock jsonBlock);
typedef TokenNetworking *(^TokenResponseTextBlock)(TokenNetSuccessTextBlock textBlock);

//willFailure
typedef TokenNetworking *(^TokenWillFailureBlock)(TokenNetFailureParameterBlock failureBlock);

@interface TokenNetworking : NSObject
+(instancetype)networking;
@end

@interface TokenNetworking(Chain)
@property(nonatomic ,copy ,readonly) TokenNetParametersBlock postWithURL;
@property(nonatomic ,copy ,readonly) TokenNetParametersBlock getWithURL;
@property(nonatomic ,copy ,readonly) TokenSendRequestBlock   request;
@property(nonatomic ,copy ,readonly) TokenChainRedirectBlock willRedict;
@property(nonatomic ,copy ,readonly) TokenResponseJSONBlock  willResponseJSON;
@property(nonatomic ,copy ,readonly) TokenResponseTextBlock  willResponseText;
@property(nonatomic ,copy ,readonly) TokenResponseJSONBlock  responseJSON;
@property(nonatomic ,copy ,readonly) TokenResponseTextBlock  responseText;
@property(nonatomic ,copy ,readonly) TokenWillFailureBlock   willFailure;
@property(nonatomic ,copy ,readonly) TokenNetFailureBlock    failure;
@end
