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
    NSLog(@"viewDidLoad");
}

- (void)tokenUpload {
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

- (void)tokenSingleRequest {
    NSString *url = @"https://www.baidu.com";

    TokenNetworking
    .networking
    .requestWith(
                 NSMutableURLRequest
                 .token_requestWithURL(url)
                 .token_setTimeout(10)
                 .token_setMethod(@"GET")
                 )
    .responseData(^(NSURLSessionTask * _Nonnull task, NSData * _Nonnull responseData) {

    })
    .responseJSON(^(NSURLSessionTask * _Nonnull task, NSError * _Nonnull jsonError, id  _Nonnull responsedObj) {
        NSLog(@"%@,%@",jsonError,responsedObj);
    })
    .responseText(^(NSURLSessionTask * _Nonnull task, NSString * _Nonnull responsedText) {
        NSLog(@"%@,%@",task,responsedText);
    })
    .failure(^(NSError * _Nonnull error){
        NSLog(@"%@", error);
    });
}

-(void)tokenMoreRequest {
    NSString *url = @"https://www.baidu.com";
    NSMutableURLRequest *request = NSMutableURLRequest
    .token_requestWithURL(url)
    .token_setMethod(@"GET")
    .token_setTimeout(10);

    TokenNetMicroTask *taskA = TokenNetworking
    .networking
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task A error");
    })
    /// next是指第一个请求处理完毕再发送第二个请求，而且.next之后返回的 TokenNetworking 对象，才可以使用 request 方法
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task A2 error");
    });
    
    TokenNetMicroTask *taskB = TokenNetworking.networking
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task B error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task B2 error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task B3 error");
    });
    
    TokenNetMicroTask *taskC = TokenNetworking.allTasks(@[taskA, taskB], ^{
        NSLog(@"--> AB 完成");
    })
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task C error");
    });
    
    TokenNetMicroTask *taskD = TokenNetworking.networking
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task d error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task d2 error");
    });
    
    TokenNetworking.allTasks(@[taskC, taskD], ^{
        NSLog(@"--> fuck all");
    })
    .makeRequest(^NSURLRequest * _Nonnull{
        NSLog(@"--> make request");
        NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
        return [NSURLRequest requestWithURL:url];
    })
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task eee error");
    });
}

- (void)testFunc {
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"第一个异步任务");
        dispatch_group_leave(group);
    });
    dispatch_group_enter(group);

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"第二个异步任务");
        dispatch_group_leave(group);
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"我的两个任务完成了");
    });
}
- (IBAction)aaaaa:(id)sender {
//    [self testFunc];
    [self tokenMoreRequest];
}


@end
