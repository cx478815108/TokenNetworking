//
//  TokenHTTPBodyStream.h
//  TokenNetworking
//
//  Created by cxtemp on 2019/6/12.
//  Copyright © 2019 Token. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenHTTPBodyStream : NSInputStream
@property (nonatomic, assign  ) NSStringEncoding stringEncoding;
@property (nonatomic, assign  ) NSTimeInterval readDelay;
@property (nonatomic, readonly) NSString *boundary;
@property (nonatomic, assign  ) unsigned long long maxBytesForRead;
@property (nonatomic, readonly, assign) unsigned long long length;
@property (nonatomic, readonly, weak) NSMutableURLRequest *request;

- (instancetype)initWithRequest:(NSMutableURLRequest *)request;

- (void)prepareForUpload;
- (void)appendParameters:(NSDictionary *)parameters;
- (void)appendFilePath:(NSString *)filePath fileName:(nullable NSString *)fileName name:(nullable NSString *)name;
- (void)appendData:(NSData *)data fileName:(nullable NSString *)fileName name:(nullable NSString *)name;
@end

NS_ASSUME_NONNULL_END
