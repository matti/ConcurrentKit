ConcurrentKit
=============

Concurrency made easy with promise/future like syntax for OS X and iOS. This library greatly simplifies the work need to make async task in objc.
This library eliminates the rightward drift problem created when chaining multiple block based async task together.

It is important to note, while this borrows from promises their syntax, it is not designed as a A+ compliant promise library.
I was inspired to create this library after seeing [mxcl](https://github.com/mxcl) promiseKit library.
If you want a compliant promise library, check it out [here](https://github.com/mxcl/PromiseKit).

The best way to explain what the library does is through examples.
## examples ##

```objc
    DCTask *task = [DCTask new];
    task.begin(^{
        NSLog(@"let's begin a background thread");
        sleep(10); //a example of a long running task
        return @10; //something we got from the long running task
    }).thenMain(^(NSNumber *num){
        NSLog(@"first: %@",num); //this would be a 10
        self.navigationItem.rightBarButtonItem.enabled = NO;
        return nil; //have to return something
    }).then(^{
        return [DCHTTPTask GET:@"http://www.vluxe.io"];
    }).thenMain(^(id object){
        NSString *str = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
        NSLog(@"web request finished: %@",str);
        //do something on the main thread.
        self.navigationItem.rightBarButtonItem.enabled = YES;
        return nil;
    }).catch(^(NSError *error){
        NSLog(@"got an error: %@",error);
        self.navigationItem.rightBarButtonItem.enabled = NO;
    });
    [task start];
```

This greatly simplifies switching between threads and eliminates rightward drift. This chain can go on as long as needed.

## more details to come...

## Requirements ##

ConcurrentKit requires at least iOS 6 or OS X 10.8.


## License ##

ConcurrentKit is license under the Apache License.

## Contact ##

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam
