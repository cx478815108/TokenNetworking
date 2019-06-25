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

/**
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
 - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
 - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.

 @param string The string to be percent-escaped.

 @return The percent-escaped string.
 */
extern NSString *TokenPercentEscapedStringFromString(NSString *string);

/**
 A helper method to generate encoded url query parameters for appending to the end of a URL.

 @param parameters A dictionary of key/values to be encoded.

 @return A url encoded query string
 */
extern NSString *TokenQueryStringFromParameters(NSDictionary *parameters);
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromKeyAndValue(NSString *_Nullable key, id value);

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
