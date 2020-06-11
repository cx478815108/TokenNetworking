//
//  TokenHTTPBodyComponent.h
//  TokenNetworking
//
//  Created by 武嘉晟 on 2020/2/23.
//  Copyright © 2020 Token. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TokenHTTPBodyComponentType) {
    TokenHTTPBodyComponentTypeFile,       // 文件地址
    TokenHTTPBodyComponentTypeData,       // 二进制的NSData
    TokenHTTPBodyComponentTypeParameters, // post 参数
    TokenHTTPBodyComponentTypeUnknown
};

NS_ASSUME_NONNULL_BEGIN

/**
TokenHTTPBodyComponent: 每个上传的数据模型，比如：二进制文件，参数列表等
内部会对每个数据进行包装，添加必要的头部，数据实体，尾部，这三个部分均使用3个NSInputStream 进行数据的读取。

TokenHTTPBodyStream: 将多个TokenHTTPBodyComponent 组合成流的形式，并提供给request.HTTPBodyStream
*/
@interface TokenHTTPBodyComponent : NSObject

@property (nonatomic, readonly) TokenHTTPBodyComponentType  componentType;
@property (nonatomic, assign  ) NSStringEncoding            stringEncoding;
@property (nonatomic, readonly) NSString                    *boundary;
@property (nonatomic, readonly) NSError                     *streamError;
@property (nonatomic, readonly, assign) unsigned long long  bodyLength;

/// 表单上的字段名
@property (nonatomic, copy, nullable) NSString *name;
/// 保存的文件名
@property (nonatomic, copy, nullable) NSString *fileName;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)componentWithFileURL:(NSURL *)fileURL boundary:(NSString *)boundary;
+ (instancetype)componentWithData:(NSData *)data boundary:(NSString *)boundary;
+ (instancetype)componentWithParameters:(NSDictionary *)parameters boundary:(NSString *)boundary;
+ (instancetype)httpBodyEndComponentWithBoundray:(NSString *)boundray stringEncoding:(NSStringEncoding)stringEncoding;

- (void)prepareForRead;
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length;
- (BOOL)hasBytesAvailable;

@end

NS_ASSUME_NONNULL_END
