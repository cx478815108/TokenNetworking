# TokenNetworking
This tool may be useful!


**Code**

```
    TokenNetworking.networking()
    .sendRequest(^NSURLRequest *(TokenNetworking *netobj) {
        return NSMutableURLRequest.token_requestWithURL(@"https://xxxx/xx/xx.html")
                                  .token_setMethod(@"GET")
                                  .token_setUA(UA)
                                  .token_setTimeout(30);
    })
    .transform(^id(TokenNetworking *netWorkingObj, id responsedObj) {
        return [netWorkingObj HTMLTextSerializeWithData:responsedObj];
    })
    .finish(^(TokenNetworking *netWorkingObj,NSURLSessionTask *task, id responsedObj) {
        NSLog(@"html text = %@",responsedObj);
    }, ^(TokenNetworking *netobj,NSError *error) {
        NSLog(@"error,%@",error);
    })
    .afterSendRequest(^NSURLRequest *(TokenNetworking *netobj) {
        NSString *transformURL = @"https://xxx/xx/xxxxx.json";
        return NSMutableURLRequest.token_requestWithURL(transformURL)
                                  .token_setMethod(@"POST");
    })
    .transform(^id(TokenNetworking *netWorkingObj, id responsedObj) {
        return [netWorkingObj JSONSerializeWithData:responsedObj failure:nil];
    })
    .finish(^(TokenNetworking *netWorkingObj,NSURLSessionTask *task, id responsedObj) {
        NSLog(@"%@",responsedObj);
        
    }, ^(TokenNetworking *netWorkingObj, NSError *error) {
        NSLog(@"error,%@",error);
    });
    
    //transform block will handle the data in a background thread.
    // see TokenNetworking.h for more details!
```


