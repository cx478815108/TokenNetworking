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

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch ");
    [self upload];
}


@end
