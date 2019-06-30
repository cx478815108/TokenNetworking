//
//  ViewController.m
//  TokenNetworking
//
//  Created by cxtemp on 2019/6/9.
//  Copyright © 2019 Token. All rights reserved.
//

#import "ViewController.h"
#import "TokenHTTPBodyStream.h"
#import "TokenNetworking.h"

@interface ViewController () <NSURLSessionTaskDelegate, NSStreamDelegate>
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) TokenHTTPBodyStream *stream;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _queue = [[NSOperationQueue alloc] init];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:_queue];
}

- (void)request {
    TokenNetworking
    .networking
    .requestWith(
                 NSMutableURLRequest
                 .token_requestWithURL(@"urlStr")
                 .token_setUA(@"UAvalue")
                 .token_setPolicy(NSURLRequestUseProtocolCachePolicy)
                 .token_setMethod(@"POST")
                 .token_handleCookie(YES)
                 .token_setTimeout(25)
                 .token_addHeaderValues(
                                        @{
                                          /// 设置 请求头
                                          @"key1": @"value1",
                                          @"key2": @"value2"
                                          }
                                        )
                 .token_setHTTPParameter(
                                         @{
                                           /// 设置 HTTPBody
                                           @"key1": @"value1",
                                           @"key2": @"value2"
                                           }
                                         )
                 )
    /// 重试次数只可以设置 1 2 3
    .retryCount(1)
    /// 下面四个设置回调处理的闭包并非必选，偶是选用
    .responseData(^(NSURLSessionTask * _Nonnull task, NSData * _Nonnull responseData) {
        NSLog(@"--> Task responseData");
    })
    .responseJSON(^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull jsonError, id  _Nonnull responsedObj) {
        NSLog(@"--> Task responsedObj");
    })
    .responseText(^(NSURLSessionTask * _Nonnull task, NSString * _Nonnull responsedText) {
        NSLog(@"--> Task responsedText");
    })
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task Error");
    });
}

- (void)getWithUrl {
    TokenNetworking
    .networking
    .getWithURL(
                @"urlStr",
                /// 设置 HTTPBody
                @{
                  @"key1": @"value1",
                  @"key2": @"value2"
                  }
                )
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task Error");
    });
}

- (void)postWithUrl {
    TokenNetworking
    .networking
    .postWithURL(
                 @"urlStr",
                 /// 设置 HTTPBody
                 @{
                   @"key1": @"value1",
                   @"key2": @"value2"
                   }
                 )
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task Error");
    });
}

- (void)taskInSerialQueue {
    TokenNetworking
    .networking
    .getWithURL(@"urlStr", nil)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task A Error");
    })
    .next
    .postWithURL(
                 @"urlStr",
                 /// 设置 HTTPBody
                 @{
                   @"key1": @"value1",
                   @"key2": @"value2"
                   }
                 )
    .retryCount(1)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task B Error");
    })
    .next
    .getWithURL(@"urlStr", nil)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task C %@",error);
    });
}

- (void)taskInSerialQueueByMakeRequest {
    __block NSString *urlTwo;
    
    TokenNetworking
    .networking
    .getWithURL(@"urlStr", nil)
    .retryCount(1)
    .responseData(^(NSURLSessionTask * _Nonnull task, NSData * _Nonnull responseData) {
        urlTwo = @"urlTwoFromResponseData";
        NSLog(@"--> Task A %@",responseData);
    })
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task A %@",error);
    })
    .next
    .makeRequest(^NSURLRequest * _Nonnull{
        return NSMutableURLRequest
        /// 第二个请求的参数可以使用第一个请求的回包数据
        .token_requestWithURL(urlTwo);
    })
    .retryCount(1)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task B %@",error);
    });
}

- (void)taskAfterMoreTaskInCurrentQueue {
    NSError *error;
    NSMutableURLRequest *request = NSMutableURLRequest
    .token_requestWithURL(@"urlStr")
    .token_setJSONParameter(
                            @{
                              @"key1": @"value1",
                              @"key2": @"value2"
                              },
                            error
                            );
    
    TokenNetMicroTask *taskA = TokenNetworking
    .networking
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task A Error");
    })
    .next
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task A2 Error");
    });
    
    TokenNetMicroTask *taskB = TokenNetworking
    .networking
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task B Error");
    })
    .next
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task B2 Error");
    })
    .next
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task B3 Error");
    });
    
    TokenNetMicroTask *taskC = TokenNetworking
    .allTasks(@[taskA, taskB], ^{
        NSLog(@"--> AB 完成");
    })
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task C Error");
    });
    
    TokenNetMicroTask *taskD = TokenNetworking
    .networking
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task D Error");
    })
    .next
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task D2 Error");
    });
    
    TokenNetworking
    .allTasks(@[taskC, taskD], ^{
        NSLog(@"--> fuck all");
    })
    .requestWith(request)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task E Error");
    });
}

- (void)redirect {
    TokenNetworking
    .networking
    .getWithURL(@"urlStr", nil)
    .retryCount(1)
    .redirect(^NSURLRequest * _Nonnull(NSURLRequest * _Nonnull request, NSURLResponse * _Nonnull response) {
        /// 从 request 和 response 中获取信息进行业务判断，返回所需的新的 request
        NSMutableURLRequest *newRequest = NSMutableURLRequest
        .token_requestWithURL(@"newUrlStr")
        .token_setMethod(@"POST");
        return newRequest;
    })
    .responseText(^(NSURLSessionTask * _Nonnull task, NSString * _Nonnull responsedText) {
        NSLog(@"--> Task responsedText");
    })
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task Error");
    });
}

- (void)uploadTask {
    
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/upload"];
    NSMutableURLRequest *request= [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    TokenHTTPBodyStream *stream = [[TokenHTTPBodyStream alloc] initWithRequest:request];
    NSString *filePath = @"/Users/cxtemp/Desktop/test.zip";
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    NSDictionary *parameters = @{
                                 @"userName":@"Alice"
                                 };
    [stream appendParameters:parameters];
    [stream appendFilePath:filePath fileName:@"abc.html" name:@"logo"];
    [stream appendData:data fileName:@"test.zip" name:@"logo"];
    [stream prepareForUpload];
    
    NSURLSessionUploadTask *task = [_session uploadTaskWithStreamedRequest:request];
    [task resume];
    
}

- (void)createNetworking {
    TokenNetworking
    .createNetworking(
                      /// 可以自己设置 NSURLSessionConfiguration 和 delegateQueue
                      [NSURLSessionConfiguration defaultSessionConfiguration],
                      [[NSOperationQueue alloc] init]
                      )
    .getWithURL(@"urlStr", nil)
    .retryCount(1)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"%@",error);
    });
}

- (IBAction)funcOne:(id)sender {
    [self request];
}

- (IBAction)funcTwo:(id)sender {
    [self getWithUrl];
}

- (IBAction)funcThree:(id)sender {
    [self postWithUrl];
}

- (IBAction)funcFour:(id)sender {
    [self taskInSerialQueue];
}

- (IBAction)funcFive:(id)sender {
    [self taskInSerialQueueByMakeRequest];
}

- (IBAction)funcSix:(id)sender {
    [self taskAfterMoreTaskInCurrentQueue];
}

- (IBAction)funcSeven:(id)sender {
    [self redirect];
}

- (IBAction)funcEight:(id)sender {
    [self uploadTask];
}

- (IBAction)funcNine:(id)sender {
    [self createNetworking];
}

@end
