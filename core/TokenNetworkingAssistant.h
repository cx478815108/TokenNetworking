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
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromKeyAndValue(NSString * _Nonnull key, id value);
extern NSArray <TokenQueryStringPair *> * TokenQueryStringPairsFromDictionary(NSDictionary *dictionary);

NS_ASSUME_NONNULL_END
