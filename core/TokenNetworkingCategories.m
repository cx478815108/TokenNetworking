//
//  TokenNetworkingCategories.m
//
//  Created by 陈雄&武嘉晟 on 2017/9/11.
//  Copyright © 2017年 com.feelings. All rights reserved.
//

#import "TokenNetworkingCategories.h"
#import "TokenNetworkingAssistant.h"
#pragma mark - NSObject分类

@implementation NSObject (TokenNetworking)

- (NSDictionaryUnpackBlock)token_dicUnpackValue {
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

#pragma mark - NSDictionary分类

@implementation NSDictionary (TokenNetworking)

+ (NSString *)token_paramterTransformToString:(NSDictionary *)parameter {
    if (parameter && [parameter isKindOfClass:[NSDictionary class]]) {
        if (parameter.allKeys.count == 0) {
            return nil;
        }
        NSMutableString *_postString = [NSMutableString string];
        for (NSString *key in parameter.allKeys) {
            [_postString appendString:[NSString stringWithFormat:@"%@=%@&",key,parameter[key]]];
        }
        return [_postString substringToIndex:_postString.length - 1];
    }
    return nil;
}

+ (NSString *)token_dictionaryToJSONString:(NSDictionary *)dic {
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end

#pragma mark - NSMutableURLRequest分类

@implementation NSMutableURLRequest (TokenNetworking)

// 设置URL
+ (NSURLRequestInstanceBlock)token_requestWithURL {
    return ^NSMutableURLRequest *(NSString *url) {
        return [self token_requestWithURLString:url];
    };
}

+ (NSMutableURLRequest *)token_requestWithURLString:(NSString *)string {
    return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:string]];
}

// 设置timeout
- (NSURLRequestTimeoutBlock)token_setTimeout {
    return ^NSMutableURLRequest *(NSTimeInterval timeout) {
        self.timeoutInterval = timeout;
        return self;
    };
}

// 设置UA
- (NSURLRequestStringSetBlock)token_setUA {
    return ^NSMutableURLRequest *(NSString *value) {
        [self setValue:value forHTTPHeaderField:@"User-Agent"];
        return self;
    };
}

// 设置Cache策略
- (NSURLRequestPolicySetBlock)token_setPolicy {
    return ^NSMutableURLRequest *(NSURLRequestCachePolicy policy) {
        self.cachePolicy = policy;
        return self;
    };
}

// 设置HTTP请求方法
- (NSURLRequestStringSetBlock)token_setMethod {
    return ^NSMutableURLRequest *(NSString *value) {
        self.HTTPMethod = value;
        return self;
    };
}

// 设置是否处理Cookie
- (NSURLRequestBOOLSetBlock)token_handleCookie {
    return ^NSMutableURLRequest *(BOOL value) {
        self.HTTPShouldHandleCookies = value;
        return self;
    };
}

// 添加请求头
- (NSURLRequestDictionarySetBlock)token_addHeaderValues {
    return ^NSMutableURLRequest *(NSDictionary *dic) {
        for (NSString *key in dic.allKeys) {
            [self setValue:dic[key] forHTTPHeaderField:key];
        }
        return self;
    };
}

// 设置请求体
- (NSURLRequestDictionarySetBlock)token_setHTTPParameter {
    return ^NSMutableURLRequest *(NSDictionary *dic) {
        NSString *httpBodyString = TokenQueryStringFromParameters(dic);
        self.HTTPBody = [httpBodyString dataUsingEncoding:NSUTF8StringEncoding];
        return self;
    };
}

// 设置请求体
- (NSURLRequestJSONSetBlock)token_setJSONParameter {
    return ^NSMutableURLRequest *(NSDictionary *dic ,NSError *error) {
        if (dic) {
            self.HTTPBody = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
        }
        return self;
    };
}

@end

#pragma mark - NSError分类

@implementation NSError (TokenNetworking)

+ (NSError *)token_errorWithCode:(NSInteger)code
                     description:(NSString *)description {
    return [NSError errorWithDomain:@"com.token.networking" code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+ (TokenNetworkingErrorInstacnceBlock)token_errorWithInfo {
    return ^NSError *(NSInteger code, NSString *errorDescription) {
        return [NSError token_errorWithCode:code description:errorDescription];
    };
}

+ (NSError *)token_netError {
    return [self token_errorWithCode:3003 description:@"请求失败！"];
}

@end
