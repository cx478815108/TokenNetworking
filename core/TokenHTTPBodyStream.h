//
//  TokenHTTPBodyStream.h
//  TokenNetworking
//
//  Created by cxtemp on 2019/6/12.
//  Copyright © 2019 Token. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 流式上传使用的Body流
@interface TokenHTTPBodyStream : NSInputStream

/**
 字符串编码，默认NSUTF8StringEncoding
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/**
 数据读取的延迟时间，默认不延迟
 */
@property (nonatomic, assign) NSTimeInterval readDelay;

/**
 http协议 formdata上传的 分割边界，拥有默认值，也可以自定义
 */
@property (nonatomic, readonly) NSString *boundary;

/**
 一次性读取的最大字节数，默认NSIntegerMax
 */
@property (nonatomic, assign) unsigned long long maxBytesForRead;

/**
 整个传输的字节数
 */
@property (nonatomic, readonly, assign) unsigned long long length;

/**
 请求
 */
@property (nonatomic, readonly, weak) NSMutableURLRequest *request;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithRequest:(NSMutableURLRequest *)request;

- (void)prepareForUpload;

/**
 添加要post的表单参数
 
 @param parameters 表单参数
 */
- (void)appendParameters:(NSDictionary *)parameters;

/**
 添加一个文件路径，将会通过NSInputStream 读取这个文件并通过流的形式上传
 
 @param filePath 文件路径
 @param fileName 告诉后台的文件名
 @param name 表单上传的name 字段
 */
- (void)appendFilePath:(NSString *)filePath fileName:(nullable NSString *)fileName name:(nullable NSString *)name;

/**
 添加一个NSData，将会通过NSInputStream 读取这个data并通过流的形式上传
 
 @param data 二进制数据
 @param fileName 告诉后台的文件名
 @param name 表单上传的name 字段
 */
- (void)appendData:(NSData *)data fileName:(nullable NSString *)fileName name:(nullable NSString *)name;

@end

NS_ASSUME_NONNULL_END
