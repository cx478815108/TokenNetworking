//
//  TokenNetworking.m
//  NewHybrid
//
//  Created by 陈雄&武嘉晟 on 2018/6/11.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenNetworking.h"
#import <pthread.h>

@interface TokenNetworkingHandler : NSObject

@property (nonatomic, assign) NSInteger                        taskID;
@property (nonatomic, copy  ) TokenRequestMakeBlock            requestMakeBlock;
@property (nonatomic, copy  ) TokenChainRedirectParameterBlock redirectBlock;
@property (nonatomic, copy  ) TokenNetSuccessJSONBlock         willResponseJSON;
@property (nonatomic, copy  ) TokenNetSuccessTextBlock         willResponseText;
@property (nonatomic, copy  ) TokenNetFailureParameterBlock    willFailure;
@property (nonatomic, copy  ) TokenNetSuccessJSONBlock         responseJSON;
@property (nonatomic, copy  ) TokenNetSuccessTextBlock         responseText;
@property (nonatomic, copy  ) TokenNetFailureParameterBlock    failureBlock;
@property (nonatomic, strong) NSMutableData                    *data;

@end

@implementation TokenNetworkingHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
    }
    return self;
}
@end

@interface TokenNetworking () <NSURLSessionTaskDelegate>

@end

@implementation TokenNetworking {
    // 信号量，保证一条链条上每个请求是one by one的
    dispatch_semaphore_t _sendSemaphore;
    NSURLSession *_session;
    // 保存每个请求的相关处理的block
    NSMutableArray *_handles;
    // 互斥锁，数组的存取不可以多线程操作，需要用互斥锁锁起来，保证在任一时刻，只能有一个线程访问该对象
    pthread_mutex_t _lock;
}

// 初始化方法，生成TokenNetworking对象
+ (instancetype)networking {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:[TokenNetworking processQueue]];
        _handles = @[].mutableCopy;
        _sendSemaphore = dispatch_semaphore_create(1);
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

/**
 *  根据设备活跃核心数获取到最大并发数合适的操作队列
 @return 操作队列
 */
+ (NSOperationQueue *)processQueue {
    static dispatch_once_t onceToken;
    static NSOperationQueue *processQueue;
    dispatch_once(&onceToken, ^{
        NSProcessInfo *info = [NSProcessInfo processInfo];
        NSUInteger defaultNumber = [info activeProcessorCount];
        processQueue = [[NSOperationQueue alloc] init];
        // 并发数 = 核心数 * 2
        processQueue.maxConcurrentOperationCount = defaultNumber * 2;
    });
    return processQueue;
}

/**
 *  串行队列 放入的任务是执行task
 */
+ (dispatch_queue_t)searalQueue {
    // 需要把任务派发到串行队列上，并且保证任务有序的一个一个的从中拉出来执行
    static dispatch_queue_t obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = dispatch_queue_create("com.tokenNetworking.queue", DISPATCH_QUEUE_SERIAL);
    });
    return obj;
}

#pragma mark - 互斥锁

- (void)lock {
    pthread_mutex_lock(&_lock);
}

- (void)unlock {
    pthread_mutex_unlock(&_lock);
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    // 加锁，通过taskID取出某个task对应的handls数据结构，从handle取出对应的block执行任务
    [self lock];
    TokenNetworkingHandler *handle = [self getHandleWithTaskID:task.taskIdentifier];
    [self unlock];
    if (handle.redirectBlock) {
        NSURLRequest *newRequest = handle.redirectBlock(request ,response);
        completionHandler(newRequest);
    } else {
        completionHandler(request);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    // 加锁，通过taskID取出某个task对应的handls数据结构
    [self lock];
    TokenNetworkingHandler *handle = [self getHandleWithTaskID:dataTask.taskIdentifier];
    [self unlock];
    [handle.data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    // .responseJSON .responseText 的任务执行完毕 才可以发送下一个请求
    [self lock];
    TokenNetworkingHandler *handler = [self getHandleWithTaskID:task.taskIdentifier];
    // 此次取出handle，已经到了didCompleteWithError回调方法，所以无需继续保存handle数据结构
    [_handles removeObject:handler];
    if (_handles.count == 0) {
        // 最后的任务都被拉出来进行处理，已经没有任务还需要被处理，所以结束任务，释放handles数组
        [_session finishTasksAndInvalidate];
        _handles = nil;
    }
    [self unlock];
    if (error) {
        // 错误处理 -> 直接增加一个信号量，任务可能成功，也可能失败，在此需要释放信号量，因为不释放的话，下一个请求由于没有信号量消耗永远卡住
        // willFailure这个Block是可以在其他线程处理的任务块
        !handler.willFailure?:handler.willFailure(error);
        if (handler.failureBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler.failureBlock(error);
                dispatch_semaphore_signal(self->_sendSemaphore);
            });
        } else {
            // 就算调用方没写失败block，也需要释放信号量
            dispatch_semaphore_signal(self->_sendSemaphore);
        }
        // 有错误就需要退出此代理方法执行，不执行剩余语句，不要删除这个 return ;
        return ;
    }
    // 从handle中取出对应的data，进行解析
    NSData *data = handler.data;
    NSError *jsonError;
    id json = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:&jsonError];
    // willResponseJSON代码块可以在其他线程执行
    !handler.willResponseJSON?:handler.willResponseJSON(task,jsonError,json);
    // 考虑到数据解析完毕后，有json数据回调块，还有text数据回调块，所以信号量的释放格外重要，需要注意
    if (handler.responseJSON) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 主线程执行responseJSON代码块
            handler.responseJSON(task,error,json);
        });
    }
    // 从data转换成字符串
    NSString *textString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // will块代码是可以在其他线程执行的
    !handler.willResponseText?:handler.willResponseText(task,textString);
    // 上面的代码没有释放信号量，下面需要进行释放
    if (handler.responseText) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 如果有text代码块则执行这一块任务
            handler.responseText(task,textString);
            dispatch_semaphore_signal(self->_sendSemaphore);
        });
    } else {
        dispatch_semaphore_signal(self->_sendSemaphore);
    }
}

#pragma mark - getter

// 根据taskID获取对应的handle
- (TokenNetworkingHandler *)getHandleWithTaskID:(NSUInteger)taskID {
    TokenNetworkingHandler *handle;
    for (NSInteger i = 0; i <_handles.count; i++) {
        handle = [_handles objectAtIndex:i];
        if (handle.taskID == taskID) {
            break;
        }
    }
    return handle;
}

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

@end

#pragma mark - chain 链式调用的基础

@implementation TokenNetworking(Chain)

- (TokenSendRequestBlock)request {
    return ^TokenNetworking *(TokenRequestMakeBlock make) {
        // make是使用方传入的 我们使用这个make() 去拿到使用方返回给我们的NSURLRequest
        if (!make) return self;
        //多线程数组操作，加锁进入临界区
        [self lock];
        TokenNetworkingHandler *handle = [[TokenNetworkingHandler alloc] init];
        // 将make 保存在handle 里面
        handle.requestMakeBlock = make;
        // handle加入handles数组
        [self->_handles addObject:handle];
        [self unlock];
        dispatch_async([self.class searalQueue], ^{
            // 此处使用信号量阻塞 当信号量 > 0的时候才会往下运行 否则一直卡在此处
            dispatch_semaphore_wait(self->_sendSemaphore, DISPATCH_TIME_FOREVER);
            // 当网络任务执行完毕 在运行了 .responseText 或者.responseJSON后，我们释放一个信号量；再或者直接error也会释放信号量。下面的代码接着运行
            // get top
            if (handle.requestMakeBlock) {
                // 此处我们执行上面保存的block 拿到request
                NSURLRequest *request = handle.requestMakeBlock();
                // 生成一个task
                NSURLSessionTask *task = [self->_session dataTaskWithRequest:request];
                handle.taskID = task.taskIdentifier;
                // task 开始运行
                [task resume];
            }
        });
        return self;
    };
}

// 下面两个方法都是对于上面request的封装，使得使用者调用更加简单
- (TokenNetParametersBlock)postWithURL {
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

- (TokenNetParametersBlock)getWithURL {
    return ^TokenNetworking *(NSString *urlString,NSDictionary *parameters) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.token_setMethod(@"GET");
        if (parameters) {
            request.token_setHTTPParameter(parameters);
        }
        return self.request(^NSURLRequest *(void) {
            return request;
        });
    };
}

- (TokenChainRedirectBlock)willRedict {
    return ^TokenNetworking *(TokenChainRedirectParameterBlock redirectParameter) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.redirectBlock = redirectParameter;
        }
        return self;
    };
}

- (TokenResponseJSONBlock)willResponseJSON {
    return ^TokenNetworking *(TokenNetSuccessJSONBlock jsonBlock) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.willResponseJSON = jsonBlock;
        }
        return self;
    };
}
- (TokenResponseJSONBlock)responseJSON {
    return ^TokenNetworking *(TokenNetSuccessJSONBlock jsonBlock) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.responseJSON = jsonBlock;
        }
        return self;
    };
}

- (TokenResponseTextBlock)willResponseText {
    return ^TokenNetworking *(TokenNetSuccessTextBlock textBlock) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.willResponseText = textBlock;
        }
        return self;
    };
}
- (TokenResponseTextBlock)responseText {
    return ^TokenNetworking *(TokenNetSuccessTextBlock textBlock) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.responseText = textBlock;
        }
        return self;
    };
}

- (TokenWillFailureBlock)willFailure {
    return ^TokenNetworking *(TokenNetFailureParameterBlock failureBlock) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.willFailure = failureBlock;
        }
        return self;
    };
}
- (TokenNetFailureBlock)failure {
    return ^TokenNetworking *(TokenNetFailureParameterBlock failure) {
        // get top
        TokenNetworkingHandler *handle = [self->_handles lastObject];
        if (handle) {
            handle.failureBlock = failure;
        }
        return self;
    };
}

@end
