# TokenNetworking

This tool may be useful!

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like TokenNetworking in your projects. You can install it with the following command:

```
$ gem install cocoapods
```

#### Podfile

To integrate TokenNetworking into your Xcode project using CocoaPods, specify it in your `Podfile`:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

target 'TargetName' do
pod 'TokenNetworking'
end
```

Then, run the following command:

```
$ pod install
```

## Architecture

### TokenNetworking

- TokenHTTPBodyStream
- TokenNetworking
- TokenNetworkingAssistant

## **Usage**

### Request

```objective-c
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
                 .token_setHTTPParameter(@{
                                           /// 设置 HTTPBody
                                           @"key1": @"value1",
                                           @"key2": @"value2"
                                           }
                                         )
                 )
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
```

### getWithUrl

```objective-c
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
```

### postWithUrl

```objective-c
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
```

### taskInSerialQueue

```objective-c
TokenNetworking
    .networking
    .getWithURL(@"urlStr", nil)
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
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task B Error");
    })
    .next
    .getWithURL(@"urlStr", nil)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task C %@",error);
    });
```

上面的三个请求会串行发送，每一个任务的回调处理完毕才会执行下一个请求。

### makeRequest

```objective-c
__block NSString *urlTwo;

    TokenNetworking
    .networking
    .getWithURL(@"urlStr", nil)
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
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"--> Task C %@",error);
    });
```

第二个请求的参数依赖于第一个请求的回包，可以使用makeRequest

### taskAfterMoreTaskInCurrentQueue

```objective-c
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
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task A Error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task A2 Error");
    });

    TokenNetMicroTask *taskB = TokenNetworking
    .networking
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task B Error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task B2 Error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task B3 Error");
    });

    TokenNetMicroTask *taskC = TokenNetworking
    .allTasks(@[taskA, taskB], ^{
        NSLog(@"--> AB 完成");
    })
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task C Error");
    });

    TokenNetMicroTask *taskD = TokenNetworking
    .networking
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task D Error");
    })
    .next
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> Task D2 Error");
    });

    TokenNetworking
    .allTasks(@[taskC, taskD], ^{
        NSLog(@"--> fuck all");
    })
    .requestWith(request)
    .failure(^(NSError * _Nonnull error){
        NSLog(@"--> task E Error");
    });
```

每一个 TokenNetworking "链条"抽象为一个微任务。

- A B 微任务内 .next 分割开的多个请求串行处理。
- A B 微任务并行处理。
- A B 彻底处理完毕会开始处理 C 任务
- C D 并行处理
- C D 彻底处理完毕进行最后一个匿名微任务的处理

### redirect

```objective-c
TokenNetworking
    .networking
    .getWithURL(@"urlStr", nil)
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
```

### createNetworking

可以自己设置 NSURLSessionConfiguration 和 delegateQueue

```objective-c
TokenNetworking
    .createNetworking(
                      /// 可以自己设置 NSURLSessionConfiguration 和 delegateQueue
                      [NSURLSessionConfiguration defaultSessionConfiguration],
                      [[NSOperationQueue alloc] init]
                      )
    .getWithURL(@"urlStr", nil)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"%@",error);
    });
```

### uploadTask

```
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
```

### createNetworking

```
TokenNetworking
    .createNetworking(
                      /// 可以自己设置 NSURLSessionConfiguration 和 delegateQueue
                      [NSURLSessionConfiguration defaultSessionConfiguration],
                      [[NSOperationQueue alloc] init]
                      )
    .getWithURL(@"urlStr", nil)
    .failure(^(NSError * _Nonnull error) {
        NSLog(@"%@",error);
    });
```

## License

TokenNetworking is released under the MIT license. 