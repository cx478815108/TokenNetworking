//
//  TokenNetworking.m
//  NewHybrid
//
//  Created by 陈雄&武嘉晟 on 2018/6/11.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenNetworking.h"

/**
 返回默认的回调队列
 
 @return DelegateQueue
 */
static NSOperationQueue *TokenNetSessionDelegateQueue() {
    static dispatch_once_t onceToken;
    static NSOperationQueue *processQueue;
    dispatch_once(&onceToken, ^{
        processQueue = [[NSOperationQueue alloc] init];
        /// 并发数 = 核心数 * 2
        processQueue.maxConcurrentOperationCount = [[NSProcessInfo processInfo] activeProcessorCount] * 2;
    });
    return processQueue;
}

@interface TokenNetMicroTask() <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, weak  ) TokenNetworking *networking;
@property (nonatomic, weak  ) dispatch_group_t taskGroup;

@property (nonatomic, copy) TokenChainRedirectParameterBlock redirectAction;
@property (nonatomic, copy) TokenNetSuccessDataBlock responseDataAction;
@property (nonatomic, copy) TokenNetSuccessTextBlock responseTextAction;
@property (nonatomic, copy) TokenNetSuccessJSONBlock responseJSONAction;
@property (nonatomic, copy) TokenNetFailureParameterBlock failureAction;
@property (nonatomic, assign) NSUInteger privateRetryCount;

@end

@interface TokenNetworking() <NSURLSessionDataDelegate>

/// 保存每一个任务
@property (nonatomic, strong) NSMutableArray <TokenNetMicroTask *> *microTasks;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) dispatch_semaphore_t operationLock;
@property (nonatomic, strong) dispatch_semaphore_t taskSemaphore;
@property (nonatomic, strong) dispatch_queue_t processQueue;

@end

@implementation TokenNetworking

+ (TokenNetworking *)networking {
    return [[self alloc] init];
}

+ (TokenNetworkingCreateBlock)createNetworking {
    return ^TokenNetworking *(NSURLSessionConfiguration *sessionConfiguration, NSOperationQueue *delegateQueue) {
        return [[TokenNetworking alloc] initWithConfiguration:sessionConfiguration delegateQueue:delegateQueue];
    };
}

- (instancetype)init
{
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:TokenNetSessionDelegateQueue()];
        [self prepare];
    }
    return self;
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration delegateQueue:(NSOperationQueue *)delegateQueue {
    if (self = [super init]) {
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:delegateQueue];
        [self prepare];
    }
    return self;
}

#pragma mark - action

- (void)prepare {
    _operationLock = dispatch_semaphore_create(1);
    _taskSemaphore = dispatch_semaphore_create(1);
    _processQueue  = dispatch_queue_create("com.tokennetworking.microtaskqueue", NULL);
    _microTasks    = [NSMutableArray array];
}

- (void)lock {
    dispatch_semaphore_wait(_operationLock, DISPATCH_TIME_FOREVER);
}

- (void)unlock {
    dispatch_semaphore_signal(_operationLock);
}

- (TokenNetMicroTask *)getMicroTaskWithTaskID:(NSUInteger)taskID {
    [self lock];
    TokenNetMicroTask *targetTask;
    for (TokenNetMicroTask *microTask in _microTasks) {
        if (microTask.dataTask.taskIdentifier == taskID) {
            targetTask = microTask;
            break;
        }
    }
    [self unlock];
    return targetTask;
}

- (TokenNetworking *)addMicroTask:(TokenNetMicroTask *)task {
    [self lock];
    [self.microTasks addObject:task];
    [self unlock];
    dispatch_async(_processQueue, ^{
        /// 串行请求的基础
        dispatch_semaphore_wait(self.taskSemaphore, DISPATCH_TIME_FOREVER);
        [task.dataTask resume];
    });
    return self;
}

- (void)removeMicroTask:(TokenNetMicroTask *)task {
    dispatch_semaphore_signal(_taskSemaphore);
    [self lock];
    [self.microTasks removeObject:task];
    
    // 没有任务，需要通知
    if (self.microTasks.count == 0) {
        /// 多任务完成执行后执行某操作的基础
        !task.taskGroup ?: dispatch_group_leave(task.taskGroup);
    }
    
    [self unlock];
}

- (void)queryFinishTasks {
    [self lock];
    if (self.microTasks.count == 0) {
        [self.session finishTasksAndInvalidate];
    }
    [self unlock];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    TokenNetMicroTask *microTask = [self getMicroTaskWithTaskID:task.taskIdentifier];
    [microTask URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    TokenNetMicroTask *microTask = [self getMicroTaskWithTaskID:dataTask.taskIdentifier];
    [microTask URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    TokenNetMicroTask *microTask = [self getMicroTaskWithTaskID:task.taskIdentifier];
    [microTask URLSession:session task:task didCompleteWithError:error];
}

#pragma mark - dot syntax
+ (TokenNetworkingTasksBlock)allTasks {
    return ^TokenNetworking *(NSArray <TokenNetMicroTask *> *tasks, dispatch_block_t finish) {
        
        BOOL enter = NO;
        __block dispatch_group_t group = dispatch_group_create();
        for (TokenNetMicroTask *task in tasks) {
            if ([task isKindOfClass:[TokenNetMicroTask class]]) {
                enter = YES;
                task.taskGroup = group;
                dispatch_group_enter(group);
            }
        }
        
        if (!enter) {
            !finish ?: finish();
            return nil;
        }
        
        TokenNetworking *networking = [TokenNetworking networking];
        dispatch_async(networking.processQueue, ^{
            dispatch_semaphore_wait(networking.taskSemaphore, DISPATCH_TIME_FOREVER);
        });
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            /// 延长group 的生命周期，block 捕获住这个 group
            group = nil;
            !finish ?: finish();
            dispatch_semaphore_signal(networking.taskSemaphore);
            [networking queryFinishTasks];
        });
        
        return networking;
    };
}

- (TokenNetRequestBlock)requestWith {
    return ^TokenNetMicroTask *_Nonnull(NSURLRequest *request) {
        TokenNetMicroTask *task = [[TokenNetMicroTask alloc] init];
        task.dataTask           = [self.session dataTaskWithRequest:request];
        task.networking         = self;
        [self addMicroTask:task];
        return task;
    };
}

- (TokenSendRequestBlock)makeRequest {
    return ^TokenNetMicroTask *_Nonnull(TokenRequestMakeBlock  _Nonnull make) {
        TokenNetMicroTask *task = [[TokenNetMicroTask alloc] init];
        task.networking         = self;
        [self lock];
        [self.microTasks addObject:task];
        [self unlock];
        
        dispatch_async(self.processQueue, ^{
            dispatch_semaphore_wait(self.taskSemaphore, DISPATCH_TIME_FOREVER);
            NSURLRequest *request = make();
            task.dataTask         = [self.session dataTaskWithRequest:request];;
            [task.dataTask resume];
        });
        return task;
    };
}

- (TokenNetParametersBlock)getWithURL {
    return ^TokenNetMicroTask *(NSString *urlString, NSDictionary *parameters) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.token_setMethod(@"GET");
        if (parameters) {
            request.token_setHTTPParameter(parameters);
        }
        return self.requestWith(request);
    };
}

- (TokenNetParametersBlock)postWithURL {
    return ^TokenNetMicroTask *(NSString *urlString, NSDictionary *parameters) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.token_setMethod(@"POST");
        if (parameters) {
            request.token_setHTTPParameter(parameters);
        }
        return self.requestWith(request);
    };
}

@end

@implementation TokenNetMicroTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _data = [NSMutableData data];
    }
    return self;
}

#pragma mark - dot syntax

- (TokenNetworking *)next {
    return _networking;
}

- (TokenChainRedirectBlock)redirect {
    return ^TokenNetMicroTask *_Nonnull(TokenChainRedirectParameterBlock redirectParameter) {
        self.redirectAction = redirectParameter;
        return self;
    };
}

- (TokenResponseDataBlock)responseData {
    return ^TokenNetMicroTask * _Nonnull(TokenNetSuccessDataBlock  _Nonnull jsonBlock) {
        self.responseDataAction = jsonBlock;
        return self;
    };
}

- (TokenResponseJSONBlock)responseJSON {
    return ^TokenNetMicroTask * _Nonnull(TokenNetSuccessJSONBlock  _Nonnull jsonBlock) {
        self.responseJSONAction = jsonBlock;
        return self;
    };
}

- (TokenResponseTextBlock)responseText {
    return ^TokenNetMicroTask * _Nonnull(TokenNetSuccessTextBlock  _Nonnull textBlock) {
        self.responseTextAction = textBlock;
        return self;
    };
}

- (TokenNetFailureBlock)failure {
    return ^TokenNetMicroTask * _Nonnull(TokenNetFailureParameterBlock  _Nonnull failure) {
        self.failureAction = failure;
        return self;
    };
}

- (TokenRetryCountBlock)retryCount {
    return ^TokenNetMicroTask * _Nonnull(NSUInteger retryCount) {
        if (retryCount >= 1) {
            self.privateRetryCount = retryCount;
        }
        return self;
    };
}

#pragma mark - delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (self.redirectAction) {
        return completionHandler(self.redirectAction(request, response));
    }
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
    if (error && _privateRetryCount) {
        /// 剩余重试次数 -1，清除错误数据，发起新的request
        _privateRetryCount -= 1;
        _data = [NSMutableData data];
        NSURLSessionDataTask *newTask = [session dataTaskWithRequest:task.currentRequest.copy];
        self.dataTask = newTask;
        return [newTask resume];
    }
    
    dispatch_block_t processFinish = ^() {
        [self.networking removeMicroTask:self];
        [self.networking queryFinishTasks];
    };
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    if (error) {
        if (self.failureAction) {
            dispatch_async(mainQueue, ^{
                !self.failureAction ?: self.failureAction(error);
            });
        }
        return processFinish();
    }
    
    NSData *data = self.data.copy;
    if (self.responseDataAction) {
        dispatch_async(mainQueue, ^{
            !self.responseDataAction ?: self.responseDataAction(task, data);
        });
    }
    
    if (self.responseJSONAction) {
        NSError *jsonError;
        id json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:&jsonError];
        dispatch_async(mainQueue, ^{
            !self.responseJSONAction ?: self.responseJSONAction(task, jsonError, json);
        });
    }
    
    if (self.responseTextAction) {
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(mainQueue, ^{
            !self.responseTextAction ?: self.responseTextAction(task, text);
        });
    }
    
    processFinish();
}

@end

