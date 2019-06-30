//
//  TokenHTTPBodyStream.m
//  TokenNetworking
//
//  Created by cxtemp on 2019/6/12.
//  Copyright © 2019 Token. All rights reserved.
//

#import "TokenHTTPBodyStream.h"
#import "TokenNetworkingAssistant.h"
#import <CoreServices/CoreServices.h>

#pragma mark -

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

#pragma mark - TokenHTTPBodyComponent

typedef NS_ENUM(NSUInteger, TokenHTTPBodyComponentType) {
    TokenHTTPBodyComponentTypeFile,       // 文件地址
    TokenHTTPBodyComponentTypeData,       // 二进制的NSData
    TokenHTTPBodyComponentTypeParameters, // post 参数
    TokenHTTPBodyComponentTypeUnknown
};

/**
 TokenHTTPBodyComponent: 每个上传的数据模型，比如：二进制文件，参数列表等
 内部会对每个数据进行包装，添加必要的头部，数据实体，尾部，这三个部分均使用3个NSInputStream 进行数据的读取。
 
 TokenHTTPBodyStream: 将多个TokenHTTPBodyComponent 组合成流的形式，并提供给request.HTTPBodyStream
 */
@interface TokenHTTPBodyComponent : NSObject

@property (nonatomic, readonly) TokenHTTPBodyComponentType componentType;
@property (nonatomic, assign  ) NSStringEncoding stringEncoding;
@property (nonatomic, readonly) NSString *boundary;
@property (nonatomic, readonly) NSError *streamError;
@property (nonatomic, readonly, assign) unsigned long long bodyLength;

/// 表单上的字段名
@property (nonatomic, copy, nullable) NSString *name;
/// 保存的文件名
@property (nonatomic, copy, nullable) NSString *fileName;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)componentWithFileURL:(NSURL *)fileURL boundary:(NSString *)boundary;
+ (instancetype)componentWithData:(NSData *)data boundary:(NSString *)boundary;
+ (instancetype)componentWithParameters:(NSDictionary *)parameters boundary:(NSString *)boundary;
+ (instancetype)httpBodyEndComponentWithBoundray:(NSString *)boundray stringEncoding:(NSStringEncoding)stringEncoding;

- (void)prepareForRead;
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length;
- (BOOL)hasBytesAvailable;

@end

#pragma mark - TokenHTTPBodyStream implementation

@interface TokenHTTPBodyStream()

@property (readwrite) NSStreamStatus streamStatus;
@property (readwrite, copy  ) NSError *streamError;
@property (nonatomic, strong) NSMutableArray <TokenHTTPBodyComponent *> *bodyComponents;
@property (nonatomic, strong) TokenHTTPBodyComponent *currentComponent;
@property (nonatomic, strong) NSEnumerator *componentsEnumerator;

@end

@implementation TokenHTTPBodyStream

@synthesize delegate;
@synthesize streamStatus;
@synthesize streamError;

- (instancetype)initWithRequest:(NSMutableURLRequest *)request
{
    self = [super init];
    if (self) {
        _request         = request;
        _stringEncoding  = NSUTF8StringEncoding;
        _maxBytesForRead = NSIntegerMax;
        _length          = 0;
        _boundary        = [NSString stringWithFormat:@"TokenBoundary+%08X%08X", arc4random(), arc4random()];
    }
    return self;
}

#pragma mark - public

- (void)prepareForUpload {
    TokenHTTPBodyComponent *component = [TokenHTTPBodyComponent httpBodyEndComponentWithBoundray:self.boundary stringEncoding:NSUTF8StringEncoding];
    _length += component.bodyLength;
    [self.bodyComponents addObject:component];
    
    [_request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
    [_request setValue:[NSString stringWithFormat:@"%@", @(_length)] forHTTPHeaderField:@"Content-Length"];
    _request.HTTPBodyStream = self;
}

- (void)appendParameters:(NSDictionary *)parameters {
    if (![parameters isKindOfClass:[NSDictionary class]]) {
        return ;
    }
    TokenHTTPBodyComponent *component = [TokenHTTPBodyComponent componentWithParameters:parameters boundary:self.boundary];
    [component prepareForRead];
    _length += component.bodyLength;
    [self.bodyComponents addObject:component];
}

- (void)appendFilePath:(NSString *)filePath fileName:(nullable NSString *)fileName name:(nullable NSString *)name {
    if (!filePath.length) {
        return ;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    TokenHTTPBodyComponent *component = [TokenHTTPBodyComponent componentWithFileURL:fileURL boundary:self.boundary];
    component.fileName                = fileName ?: @"";
    component.name                    = name ?: @"";
    [component prepareForRead];
    _length += component.bodyLength;
    [self.bodyComponents addObject:component];
}

- (void)appendData:(NSData *)data fileName:(nullable NSString *)fileName name:(nullable NSString *)name {
    if (![data isKindOfClass:[NSData class]]) {
        return ;
    }
    TokenHTTPBodyComponent *component = [TokenHTTPBodyComponent componentWithData:data boundary:self.boundary];
    component.fileName                = fileName ?: @"";
    component.name                    = name ?: @"";
    [component prepareForRead];
    _length += component.bodyLength;
    [self.bodyComponents addObject:component];
}

#pragma mark - rewrite

- (void)open {
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }
    self.componentsEnumerator = self.bodyComponents.objectEnumerator;
    self.streamStatus = NSStreamStatusOpen;
}

- (void)close {
    self.streamStatus = NSStreamStatusClosed;
}

- (id)propertyForKey:(__unused NSString *)key {
    return nil;
}

- (BOOL)setProperty:(__unused id)property forKey:(__unused NSString *)key {
    return NO;
}

- (BOOL)getBuffer:(__unused uint8_t **)buffer length:(__unused NSUInteger *)len {
    return YES;
}

- (BOOL)hasBytesAvailable {
    return [self streamStatus] == NSStreamStatusOpen;
}

- (void)scheduleInRunLoop:(__unused NSRunLoop *)aRunLoop forMode:(__unused NSString *)mode {}

- (void)removeFromRunLoop:(__unused NSRunLoop *)aRunLoop forMode:(__unused NSString *)mode {}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length {
    if ([self streamStatus] == NSStreamStatusClosed) {
        return 0;
    }
    
    NSInteger totalNumberOfBytesRead = 0;
    NSUInteger min = MIN(length, _maxBytesForRead);
    
    while ((NSUInteger)totalNumberOfBytesRead < min) {
        if (!_currentComponent || ![_currentComponent hasBytesAvailable]) {
            _currentComponent = [_componentsEnumerator nextObject];
            if (!_currentComponent) {
                break;
            }
        }
        
        NSUInteger maxLength        = min - (NSUInteger)totalNumberOfBytesRead;
        NSInteger numberOfBytesRead = [_currentComponent read:&buffer[totalNumberOfBytesRead] maxLength:maxLength];
        if (numberOfBytesRead == -1) {
            self.streamError       = _currentComponent.streamError;
            self.streamStatus      = NSStreamStatusError;
            totalNumberOfBytesRead = -1;
            break;
        } else {
            totalNumberOfBytesRead += numberOfBytesRead;
            
            if (_readDelay > 0.0f) {
                [NSThread sleepForTimeInterval:_readDelay];
            }
        }
    }
    
    return totalNumberOfBytesRead;
}

#pragma mark - getter

- (NSMutableArray <TokenHTTPBodyComponent *> *)bodyComponents {
    if (!_bodyComponents) {
        _bodyComponents = [NSMutableArray array];
    }
    return _bodyComponents;
}

@end

#pragma mark - TokenHTTPBodyComponent implementation

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
