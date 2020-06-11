//
//  TokenHTTPBodyComponent.m
//  TokenNetworking
//
//  Created by 武嘉晟 on 2020/2/23.
//  Copyright © 2020 Token. All rights reserved.
//

#import "TokenHTTPBodyComponent.h"
#import "TokenNetworkingAssistant.h"
#import <CoreServices/CoreServices.h>

static NSString *const TokenBodyCRLF = @"\r\n";

static NSString *TokenContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    }
    return contentType;
}

/**
 通过该函数，生成每个二进制数据的开头

 @param boundary 分割线
 @param name 表单name 字段
 @param fileName 文件名
 @return 包装好的字符串
 */
static NSString *TokenCreateBodyFileHeaderSign(NSString *boundary, NSString *name, NSString *fileName) {
    NSMutableString *header = [NSMutableString string];
    [header appendString:[NSString stringWithFormat:@"--%@%@", boundary, TokenBodyCRLF]];

    NSString *line = [NSString stringWithFormat:@"Content-Disposition:form-data; name=\"%@\"; filename = \"%@\"", name, fileName];
    [header appendString:line];
    [header appendString:TokenBodyCRLF];

    NSString *mimetype = TokenContentTypeForPathExtension([fileName pathExtension]);
    [header appendString:[NSString stringWithFormat:@"Content-Type:%@%@", mimetype, TokenBodyCRLF]];
    [header appendString:TokenBodyCRLF];
    return header;
}

/**
 通过这个函数将参数包装起来

 @param boundary 分割字符
 @param parameters 参数
 @return 包装好的字符串
 */
static NSString *TokenCreateBodyParamaters(NSString *boundary, NSDictionary *parameters) {
    NSMutableString *bodyContent = [NSMutableString string];

    for (NSString *key in parameters) {
        id value = parameters[key];
        NSMutableString *keyValuePart = [NSMutableString string];
        [keyValuePart appendString:[NSString stringWithFormat:@"--%@%@", boundary, TokenBodyCRLF]];
        [keyValuePart appendString:[NSString stringWithFormat:@"Content-Disposition:form-data; name=\"%@\";%@", key, TokenBodyCRLF]];
        [keyValuePart appendString:TokenBodyCRLF];
        [keyValuePart appendString:TokenPercentEscapedStringFromString([value description])];
        [bodyContent appendString:[NSString stringWithFormat:@"%@",keyValuePart]];
    }

    return bodyContent;
}


@interface TokenHTTPBodyComponent () <NSStreamDelegate>

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSInputStream *headerSignStream;
@property (nonatomic, strong) NSInputStream *trailSignStream;
@property (nonatomic, readonly, nullable) NSDictionary *parameters;

@end

@implementation TokenHTTPBodyComponent

+ (instancetype)componentWithFileURL:(NSURL *)fileURL boundary:(NSString *)boundary {
    return [[TokenHTTPBodyComponent alloc] initWithType:TokenHTTPBodyComponentTypeFile dataSource:fileURL boundary:boundary];
}

+ (instancetype)componentWithData:(NSData *)data boundary:(NSString *)boundary {
    return [[TokenHTTPBodyComponent alloc] initWithType:TokenHTTPBodyComponentTypeData dataSource:data boundary:boundary];
}

+ (instancetype)componentWithParameters:(NSDictionary *)parameters boundary:(NSString *)boundary {
    return [[TokenHTTPBodyComponent alloc] initWithType:TokenHTTPBodyComponentTypeParameters dataSource:parameters boundary:boundary];
}

+ (instancetype)httpBodyEndComponentWithBoundray:(NSString *)boundray stringEncoding:(NSStringEncoding)stringEncoding {
    NSString *bodyTrail = [NSString stringWithFormat:@"--%@--%@",boundray, TokenBodyCRLF];
    return [[TokenHTTPBodyComponent alloc] initWithString:bodyTrail stringEncoding:stringEncoding];
}

- (instancetype)initWithString:(NSString *)string stringEncoding:(NSStringEncoding)stringEncoding {
    self = [super init];
    if (self) {
        NSData *data          = [string dataUsingEncoding:stringEncoding];
        _bodyLength          += data.length;
        _inputStream          = [[NSInputStream alloc] initWithData:data];
        _inputStream.delegate = self;
        [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_inputStream open];
    }
    return self;
}

- (instancetype)initWithType:(TokenHTTPBodyComponentType)type dataSource:(id)dataSource boundary:(NSString *)boundary {
    self = [super init];
    if (self) {
        _bodyLength     = 0;
        _stringEncoding = NSUTF8StringEncoding;
        _componentType  = type;
        _boundary       = [boundary copy];
        switch (type) {
            case TokenHTTPBodyComponentTypeData:
            {
                _bodyLength += ((NSData *)dataSource).length;
                _inputStream = [[NSInputStream alloc] initWithData:dataSource];
                break;
            }
            case TokenHTTPBodyComponentTypeFile:
            {
                NSError *error          = nil;
                NSString *filePath      = [(NSURL *)dataSource path];
                NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
                if (fileAttrs && !error) {
                    _bodyLength += [fileAttrs[NSFileSize] unsignedLongLongValue];
                }

                if (error) {
                    _streamError = error;
                }

                _inputStream = [[NSInputStream alloc] initWithURL:dataSource];
                break;
            }
            case TokenHTTPBodyComponentTypeParameters:
                _parameters = [(NSDictionary *)dataSource copy];
                break;
            default:
                break;
        }

    }
    return self;
}

- (void)prepareForRead {
    if (_componentType != TokenHTTPBodyComponentTypeParameters) {
        NSString *bodyHeaderSign   = TokenCreateBodyFileHeaderSign(_boundary, _name, _fileName);
        NSData *headData           = [bodyHeaderSign dataUsingEncoding:_stringEncoding];
        _bodyLength               += headData.length;
        _headerSignStream          = [[NSInputStream alloc] initWithData:headData];
        _headerSignStream.delegate = self;
        [_headerSignStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_headerSignStream open];
    }

    if (_componentType == TokenHTTPBodyComponentTypeParameters) {
        NSString *bodyString = TokenCreateBodyParamaters(_boundary, _parameters);
        NSData *data         = [bodyString dataUsingEncoding:_stringEncoding];
        _inputStream         = [[NSInputStream alloc] initWithData:data];
        _bodyLength         += data.length;
    }

    _inputStream.delegate = self;
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_inputStream open];

    NSData *trailData         = [TokenBodyCRLF dataUsingEncoding:_stringEncoding];
    _trailSignStream          = [[NSInputStream alloc] initWithData:trailData];
    _trailSignStream.delegate = self;
    _bodyLength              += trailData.length;
    [_trailSignStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_trailSignStream open];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length {

    if (_streamError) {
        return -1;
    }

    if ([_headerSignStream hasBytesAvailable]) {
        return [_headerSignStream read:buffer maxLength:length];
    }

    if ([_inputStream hasBytesAvailable]) {
        return [_inputStream read:buffer maxLength:length];
    }

    if ([_trailSignStream hasBytesAvailable]) {
        return [_trailSignStream read:buffer maxLength:length];
    }
    return -1;
}

- (BOOL)hasBytesAvailable {
    return [_headerSignStream hasBytesAvailable] ||
    [_inputStream hasBytesAvailable]      ||
    [_trailSignStream hasBytesAvailable];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (eventCode == NSStreamEventErrorOccurred) {
        _streamError = aStream.streamError;
    }
}

@end
