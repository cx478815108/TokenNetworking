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

-(void)upload{
    
//    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/upload"];
//    NSMutableURLRequest *request= [[NSMutableURLRequest alloc] initWithURL:url];
//    request.HTTPMethod = @"POST";
//
//    TokenHTTPBodyStream *stream = [[TokenHTTPBodyStream alloc] initWithRequest:request];
//    NSString *filePath = @"/Users/cxtemp/Desktop/test.zip";
//    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
//    NSDictionary *parameters = @{
//                                 @"userName":@"Alice"
//                                 };
//    [stream appendParameters:parameters];
//    [stream appendFilePath:filePath fileName:@"abc.html" name:@"logo"];
//    [stream appendData:data fileName:@"test.zip" name:@"logo"];
//    [stream prepareForUpload];
//
//    NSURLSessionUploadTask *task = [_session uploadTaskWithStreamedRequest:request];
//    [task resume];
    
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    TokenNetMicroTask *taskA = TokenNetworking.networking
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task A error");
    })
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

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch");
    [self upload];
}


@end
