//
//  NSMutableURLRequest+TokenNetworking.m
//
//  Created by 陈雄 on 2017/9/11.
//  Copyright © 2017年 com.feelings. All rights reserved.
//

#import "TokenNetworkingCategories.h"

/**
 code from AFNetworking
 */
NSString * TokenPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

#pragma mark -

@interface TokenQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation TokenQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return TokenPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", TokenPercentEscapedStringFromString([self.field description]), TokenPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark -

NSArray * TokenQueryStringPairsFromDictionary(NSDictionary *dictionary);
NSArray * TokenQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * TokenQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (TokenQueryStringPair *pair in TokenQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * TokenQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return TokenQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * TokenQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:TokenQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:TokenQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:TokenQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[TokenQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

#pragma mark -
@implementation NSMutableURLRequest (TokenNetworking)

+(NSURLRequestInstanceBlock)token_requestWithURL{
    return ^NSMutableURLRequest *(NSString *url) {
        return  [self token_requestWithURLString:url];
    };
}

+(NSMutableURLRequest *)token_requestWithURLString:(NSString *)string{
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
}

-(NSURLRequestTimeoutBlock)token_setTimeout{
    return ^NSMutableURLRequest *(NSTimeInterval timeout) {
        self.timeoutInterval = timeout;
        return self;
    };
}

-(NSURLRequestStringSetBlock)token_setUA{
    return ^NSMutableURLRequest *(NSString *value) {
        [self setValue:value forHTTPHeaderField:@"User-Agent"];
        return self;
    };
}

-(NSURLRequestPolicySetBlock)token_setPolicy{
    return ^NSMutableURLRequest *(NSURLRequestCachePolicy policy) {
        self.cachePolicy = policy;
        return self;
    };
}

-(NSURLRequestStringSetBlock)token_setMethod{
    return ^NSMutableURLRequest *(NSString *value) {
        self.HTTPMethod = value;
        return self;
    };
}


-(NSURLRequestBOOLSetBlock)token_handleCookie{
    return ^NSMutableURLRequest *(BOOL value) {
        self.HTTPShouldHandleCookies = value;
        return self;
    };
}

-(NSURLRequestDictionarySetBlock)token_addHeaderValues{
    return ^NSMutableURLRequest *(NSDictionary *dic) {
        for (NSString *key in dic.allKeys) {
            [self setValue:dic[key] forHTTPHeaderField:key];
        }
        return self;
    };
}

-(NSURLRequestDictionarySetBlock)token_setHTTPParameter{
    return ^NSMutableURLRequest *(NSDictionary *dic) {
        NSString *httpBodyString = TokenQueryStringFromParameters(dic);
        self.HTTPBody = [httpBodyString dataUsingEncoding:NSUTF8StringEncoding];    
        return self;
    };
}

-(NSURLRequestJSONSetBlock)token_setJSONParameter{
    return ^NSMutableURLRequest *(NSDictionary *dic ,NSError *error) {
        if (dic) {
            self.HTTPBody = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
        }
        return self;
    };
}

@end


@implementation NSError (TokenNetworking)

+(TokenNetworkingErrorInstacnceBlock)token_errorWithInfo{
    return ^NSError *(NSInteger code, NSString *errorDescription) {
        return [NSError token_errorWithCode:code description:errorDescription];
    };
}

+(NSError *)token_errorWithCode:(NSInteger)code
                    description:(NSString *)description
{
    return [NSError errorWithDomain:@"com.token.networking" code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+(NSError *)token_netError{
    return [self token_errorWithCode:3003 description:@"请求失败！"];
}

@end

@implementation NSObject (TokenNetworking)

-(NSDictionaryUnpackBlock)token_dicUnpackValue{
    return ^id(NSString *key) {
        if (self && [self isKindOfClass:[NSDictionary class]]) {
            return ((NSDictionary *)self)[key];
        }
        else {
            return nil;
        }
    };
}

@end

@implementation NSDictionary (TokenNetworking)

+(NSString *)token_paramterTransformToString:(NSDictionary *)parameter
{
    if (parameter && [parameter isKindOfClass:[NSDictionary class]]) {
        if (parameter.allKeys.count == 0) { return nil;}
        NSMutableString *_postString = [NSMutableString string];
        for (NSString *key in parameter.allKeys) {
            [_postString appendString:[NSString stringWithFormat:@"%@=%@&",key,parameter[key]]];
        }
        return [_postString substringToIndex:_postString.length-1];
    }
    return nil;
}

+(NSString *)token_dictionaryToJSONString:(NSDictionary *)dic{
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end

