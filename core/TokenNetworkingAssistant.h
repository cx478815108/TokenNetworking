//
//  TokenNetworkingAssistant.h
//  TokenNetworking
//
//  Created by cxtemp on 2019/6/13.
//  Copyright © 2019 Token. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenQueryStringPair : NSObject

@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;
- (instancetype)initWithField:(id)field value:(id)value;
- (NSString *)URLEncodedStringValue;
@end

extern NSString *TokenPercentEscapedStringFromString(NSString *string);
extern NSString *TokenQueryStringFromParameters(NSDictionary *parameters);
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromKeyAndValue(NSString *_Nullable key, id value);
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromDictionary(NSDictionary *dictionary);

#pragma mark - NSDictionary
@interface NSDictionary (TokenNetworking)

+ (NSString *)token_dictionaryToJSONString:(NSDictionary *)dic;

@end

#pragma mark - NSMutableURLRequest

typedef NSMutableURLRequest *_Nonnull(^NSURLRequestInstanceBlock)(NSString *url);
typedef NSMutableURLRequest *_Nonnull(^NSURLRequestPolicySetBlock)(NSURLRequestCachePolicy policy);
typedef NSMutableURLRequest *_Nonnull(^NSURLRequestTimeoutBlock)(NSTimeInterval timeout);
typedef NSMutableURLRequest *_Nonnull(^NSURLRequestStringSetBlock)(NSString *value);
typedef NSMutableURLRequest *_Nonnull(^NSURLRequestBOOLSetBlock)(BOOL value);
typedef NSMutableURLRequest *_Nonnull(^NSURLRequestDictionarySetBlock)(NSDictionary *dic);
typedef NSMutableURLRequest *_Nonnull(^NSURLRequestJSONSetBlock)(NSDictionary *dic, NSError *_Nullable error);
typedef NSString *_Nonnull(^TokenNetworkingPostHTTPParameterBlock)(NSDictionary *parameter);

@interface NSMutableURLRequest (TokenNetworking)

@property (nonatomic, readonly, class) NSURLRequestInstanceBlock     token_requestWithURL;
@property (nonatomic, copy, readonly) NSURLRequestStringSetBlock     token_setUA;
@property (nonatomic, copy, readonly) NSURLRequestPolicySetBlock     token_setPolicy;
@property (nonatomic, copy, readonly) NSURLRequestTimeoutBlock       token_setTimeout;
@property (nonatomic, copy, readonly) NSURLRequestStringSetBlock     token_setMethod;
@property (nonatomic, copy, readonly) NSURLRequestBOOLSetBlock       token_handleCookie;
@property (nonatomic, copy, readonly) NSURLRequestDictionarySetBlock token_addHeaderValues;
@property (nonatomic, copy, readonly) NSURLRequestDictionarySetBlock token_setHTTPParameter;
@property (nonatomic, copy, readonly) NSURLRequestJSONSetBlock       token_setJSONParameter;

+ (NSMutableURLRequest *)token_requestWithURLString:(NSString *)string;

@end

#pragma mark - NSError

typedef NSError *_Nonnull(^TokenNetworkingErrorInstacnceBlock)(NSInteger code ,NSString *errorDescription);

@interface NSError (TokenNetworking)

@property (nonatomic, readonly ,class) TokenNetworkingErrorInstacnceBlock token_errorWithInfo;

+ (NSError *)token_errorWithCode:(NSInteger)code description:(NSString *)description;
+ (NSError *)token_netError;

@end

NS_ASSUME_NONNULL_END
