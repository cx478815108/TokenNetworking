//
//  TokenNetworkingCategories.h
//
//  Created by 陈雄&武嘉晟 on 2017/9/11.
//  Copyright © 2017年 com.feelings. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - NSDictionary分类

typedef NSObject *(^NSDictionaryUnpackBlock)(NSString *key);

@interface NSObject(TokenNetworking)

@property(nonatomic, copy, readonly) NSDictionaryUnpackBlock token_dicUnpackValue;

@end

@interface NSDictionary (TokenNetworking)

+ (NSString *)token_dictionaryToJSONString:(NSDictionary *)dic;

@end

#pragma mark - NSMutableURLRequest分类

typedef NSMutableURLRequest *(^NSURLRequestInstanceBlock)(NSString *url);
typedef NSMutableURLRequest *(^NSURLRequestPolicySetBlock)(NSURLRequestCachePolicy policy);
typedef NSMutableURLRequest *(^NSURLRequestTimeoutBlock)(NSTimeInterval timeout);
typedef NSMutableURLRequest *(^NSURLRequestStringSetBlock)(NSString *value);
typedef NSMutableURLRequest *(^NSURLRequestBOOLSetBlock)(BOOL value);
typedef NSMutableURLRequest *(^NSURLRequestDictionarySetBlock)(NSDictionary *dic);
typedef NSMutableURLRequest *(^NSURLRequestJSONSetBlock)(NSDictionary *dic,NSError *error);
typedef NSString *(^TokenNetworkingPostHTTPParameterBlock)(NSDictionary *parameter);

@interface NSMutableURLRequest (TokenNetworking)

@property (nonatomic, copy, readonly, class) NSURLRequestInstanceBlock      token_requestWithURL;
@property (nonatomic, copy, readonly)        NSURLRequestStringSetBlock     token_setUA;
@property (nonatomic, copy, readonly)        NSURLRequestPolicySetBlock     token_setPolicy;
@property (nonatomic, copy, readonly)        NSURLRequestTimeoutBlock       token_setTimeout;
@property (nonatomic, copy, readonly)        NSURLRequestStringSetBlock     token_setMethod;
@property (nonatomic, copy, readonly)        NSURLRequestBOOLSetBlock       token_handleCookie;
@property (nonatomic, copy, readonly)        NSURLRequestDictionarySetBlock token_addHeaderValues;
@property (nonatomic, copy, readonly)        NSURLRequestDictionarySetBlock token_setHTTPParameter;
@property (nonatomic, copy, readonly)        NSURLRequestJSONSetBlock       token_setJSONParameter;

+ (NSMutableURLRequest *)token_requestWithURLString:(NSString *)string;

@end

#pragma mark - NSError分类

typedef NSError *(^TokenNetworkingErrorInstacnceBlock)(NSInteger code ,NSString *errorDescription);

@interface NSError (TokenNetworking)

@property(nonatomic ,copy ,readonly ,class) TokenNetworkingErrorInstacnceBlock token_errorWithInfo;

+ (NSError *)token_errorWithCode:(NSInteger)code description:(NSString *)description;
+ (NSError *)token_netError;

@end
