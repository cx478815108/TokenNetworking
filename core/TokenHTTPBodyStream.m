//
//  TokenHTTPBodyStream.m
//  TokenNetworking
//
//  Created by cxtemp on 2019/6/12.
//  Copyright © 2019 Token. All rights reserved.
//

#import "TokenHTTPBodyStream.h"
#import "TokenHTTPBodyComponent.h"

#pragma mark - TokenHTTPBodyStream implementation

@interface TokenHTTPBodyStream()

@property (readwrite, assign) NSStreamStatus streamStatus;
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

    /// 设置上传请求头，分割边界
    [_request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
    /// 设置整个文件的大小
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
