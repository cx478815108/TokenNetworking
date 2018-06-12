# TokenNetworking
This tool may be useful!


**Code**

```
    NSString *loginURL = @"https://www.xxx.com";
     NSDictionary *parameter = @{
         @"userName":@"xxx",
         @"password":@"xxx"
     };
 
     TokenNetworking.networking
     .postWithURL(loginURL, parameter)
     .responseJSON(^(NSURLSessionTask *task, NSError *jsonError,id responsedObj) {
         if (jsonError) {
             NSLog(@"json parse error %@",jsonError);
         }
         if (responsedObj) {
             NSLog(@"json = %@",responsedObj);
         }
     })
 
     // or you can get Text at the same time
     .responseText(^(NSURLSessionTask *task, NSString *responsedText) {
        NSLog(@"responsedText = %@",responsedText);
     })
 
     // or you can send another request one by one
     .postWithURL(loginURL1, parameter1)
     .responseJSON(^(NSURLSessionTask *task, NSError *jsonError,id responsedObj) {
        if (jsonError) {
            NSLog(@"json parse error %@",jsonError);
        }
        if (responsedObj) {
            NSLog(@"json = %@",responsedObj);
        }
     });
 
     //custom request
 
     //creat a Request
     NSURL *url = [NSURL URLWithString:@"http://www.xxx.com"];
     NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
     request.token_setMethod(@"POST")
     .token_setTimeout(30);
 
    //send the Request
     TokenNetworking.networking
     .request(^NSURLRequest *{
         return request;
     })
     .responseText(^(NSURLSessionTask *task, NSString *responsedText) {
         NSLog(@"%@",responsedText);
     })
     .responseJSON(^(NSURLSessionTask *task, NSError *jsonError,id responsedObj) {
         if (jsonError) {
             NSLog(@"json parse error %@",jsonError);
         }
         if (responsedObj) {
             NSLog(@"json = %@",responsedObj);
         }
     });
```


