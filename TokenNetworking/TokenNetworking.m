//
//  TokenNetworking.m
//  NewHybrid
//
//  Created by 陈雄 on 2018/6/11.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenNetworking.h"
#import <pthread.h>

@interface TokenNetworkingHandler : NSObject
@property(nonatomic ,assign) NSInteger taskID;
@property(nonatomic ,copy  ) TokenChainRedirectParameterBlock redirectBlock;
@property(nonatomic ,copy  ) TokenNetSuccessJSONBlock         responseJSON;
@property(nonatomic ,copy  ) TokenNetSuccessTextBlock         responseText;
@property(nonatomic ,copy  ) TokenNetFailureParameterBlock    failureBlock;
@property(nonatomic ,copy  ) TokenNetSuccessJSONBlock         willResponseJSON;
@property(nonatomic ,copy  ) TokenNetSuccessTextBlock         willResponseText;
@property(nonatomic ,strong) NSMutableData                    *data;
@end

@implementation TokenNetworkingHandler
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
    }
    return self;
}
@end

@interface TokenNetworking()<NSURLSessionTaskDelegate>
@end

@implementation TokenNetworking{
    dispatch_semaphore_t  _sendSemaphore;
    NSURLSession         *_session;
    NSMutableArray       *_handles;
    pthread_mutex_t       _lock;
}

+(NSOperationQueue *)processQueue{
    static dispatch_once_t onceToken;
    static NSOperationQueue *processQueue;
    dispatch_once(&onceToken, ^{
        NSUInteger defaultNumber = [[NSProcessInfo processInfo] activeProcessorCount];
        processQueue = [[NSOperationQueue alloc] init];
        processQueue.maxConcurrentOperationCount = defaultNumber;
    });
    return processQueue;
}

+(dispatch_queue_t)searalQueue{
    static dispatch_queue_t obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = dispatch_queue_create("com.tokenNetworking.queue", DISPATCH_QUEUE_SERIAL);
    });
    return obj;
}

+(instancetype)networking{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration
                                                           defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:[TokenNetworking processQueue]];
        _handles       = @[].mutableCopy;
        _sendSemaphore = dispatch_semaphore_create(1);
        pthread_mutex_init(&_lock, NULL);

    }
    return self;
}

-(void)lock{
    pthread_mutex_lock(&_lock);
}

-(void)unlock{
    pthread_mutex_unlock(&_lock);
}

#pragma mark -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler{
    [self lock];
    TokenNetworkingHandler *handle = [self getHandleWithTaskID:task.taskIdentifier];
    [self unlock];
    if (handle.redirectBlock) {
        NSURLRequest *newRequest = handle.redirectBlock(request ,response);
        completionHandler(newRequest);
    }
    else {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self lock];
    TokenNetworkingHandler *handle = [self getHandleWithTaskID:dataTask.taskIdentifier];
    [self unlock];
    [handle.data appendData:data];
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    dispatch_semaphore_signal(_sendSemaphore);
    [self lock];
        TokenNetworkingHandler *handler = [self getHandleWithTaskID:task.taskIdentifier];
        [_handles removeObject:handler];
        if (_handles.count == 0) {
            [_session finishTasksAndInvalidate];
            _handles = nil;
        }
    [self unlock];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            !handler.failureBlock?:handler.failureBlock(error);
        });
        return;
    }

    NSData *transformedData = handler.data;

    if (handler.responseJSON) {
        NSError *error;
        id json = [NSJSONSerialization JSONObjectWithData:transformedData options:(NSJSONReadingAllowFragments) error:&error];
        !handler.willResponseJSON?:handler.willResponseJSON(task,error,json);
        dispatch_async(dispatch_get_main_queue(), ^{
            !handler.responseJSON?:handler.responseJSON(task,error,json);
        });
    }

    if (handler.responseText) {
        NSString *textString = [[NSString alloc] initWithData:transformedData encoding:NSUTF8StringEncoding];
        !handler.willResponseText?:handler.willResponseText(task,textString);
        dispatch_async(dispatch_get_main_queue(), ^{
            !handler.responseText?:handler.responseText(task,textString);
        });
    }
}

#pragma mark - getter
-(TokenNetworkingHandler *)getHandleWithTaskID:(NSUInteger)taskID{
    TokenNetworkingHandler *handle = nil;
    for (NSInteger i = 0; i <_handles.count; i++) {
        handle = [_handles objectAtIndex:i];
        if (handle.taskID == taskID) {
            break;
        }
    }
    return handle;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_lock);
}
@end

#pragma mark - chain
@implementation TokenNetworking(Chain)
-(TokenNetPostBlock)postWithURL{
    return ^TokenNetworking *(NSString *urlString, NSDictionary *parameters) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.token_setMethod(@"POST");
        if (parameters) {
            request.token_setHTTPParameter(parameters);
        }
        return self.request(^NSURLRequest *(void) {
            return request;
        });
    };
}

-(TokenNetURLBlock)getWithURL{
    return ^TokenNetworking *(NSString *urlString) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.token_setMethod(@"GET");
        return self.request(^NSURLRequest *(void) {
            return request;
        });
    };
}

-(TokenSendRequestBlock)request{
    return ^TokenNetworking *(TokenRequestMakeBlock make) {
        if (make == nil) return self;
        NSURLRequest *request = make();
        if (request == nil) return self;
        [self lock];
            NSURLSessionTask *task = [self->_session dataTaskWithRequest:request];
            TokenNetworkingHandler *handle = [[TokenNetworkingHandler alloc] init];
            handle.taskID = task.taskIdentifier;
            //push
            [self->_handles addObject:handle];
        [self unlock];
        dispatch_async([self.class searalQueue], ^{
            dispatch_semaphore_wait(self->_sendSemaphore, DISPATCH_TIME_FOREVER);
            [task resume];
        });
        return self;
    };
}

-(TokenChainRedirectBlock)willRedict{
    return ^TokenNetworking *(TokenChainRedirectParameterBlock redirectParameter) {
        //get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.redirectBlock = redirectParameter;
        }
        return  self;
    };
}

-(TokenResponseJSONBlock)willResponseJSON{
    return ^TokenNetworking *(TokenNetSuccessJSONBlock jsonBlock) {
        //get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.willResponseJSON = jsonBlock;
        }
        return self;
    };
}

-(TokenResponseJSONBlock)responseJSON{
    return ^TokenNetworking *(TokenNetSuccessJSONBlock jsonBlock) {
        //get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.responseJSON = jsonBlock;
        }
        return  self;
    };
}

-(TokenResponseTextBlock)willResponseText{
    return ^TokenNetworking *(TokenNetSuccessTextBlock textBlock) {
        //get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.willResponseText = textBlock;
        }
        return self;
    };
}

-(TokenResponseTextBlock)responseText{
    return ^TokenNetworking *(TokenNetSuccessTextBlock textBlock) {
        //get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.responseText = textBlock;
        }
        return self;
    };
}

-(TokenNetFailureBlock)failure{
    return ^TokenNetworking *(TokenNetFailureParameterBlock failure) {
        //get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.failureBlock = failure;
        }
        return self;
    };
}
@end
