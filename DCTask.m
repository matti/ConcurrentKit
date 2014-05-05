////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTask.m
//
//  Created by Dalton Cherry on 5/2/14.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCTask.h"

@interface DCTask ()

//This basically a singly linked list
@property(nonatomic,strong)DCTask *next;

//store the work to do
@property(nonatomic,strong)DCTask*(^work)(id);
@property(nonatomic,strong)DCAsyncTask asyncTask;
@property(nonatomic,assign)BOOL isMain;
@property(nonatomic,strong)void(^errorHandler)(id);

@end

@implementation DCTask

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)start
{
    [self runTask:self param:nil];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)runTask:(DCTask*)task param:(id)param
{
    if(!task)
        return;
    [task willStart];
    if(task.asyncTask)
    {
        task.asyncTask(^(id val){
            dispatch_async(dispatch_get_main_queue(),^{
                [self finishedTask:task result:val];
            });
        },^(NSError *error){
            [self processError:task val:error];
        });
    }
    else if(task.work)
    {
        if(task.isMain)
        {
            id val = task.work(param);
            [self finishedTask:task result:val];
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                id val = task.work(param);
                dispatch_async(dispatch_get_main_queue(),^{
                    [self finishedTask:task result:val];
                });
            });
        }
    }
    else {
        [self finishedTask:task result:param];
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)willStart
{
    //used for subclasses
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)processError:(DCTask*)currentTask val:(id)value
{
    if([value isKindOfClass:[NSError class]])
    {
        if(!self.errorHandler)
            self.errorHandler = currentTask.errorHandler;
        if(!self.errorHandler)
        {
            DCTask *task = self;
            while(!self.errorHandler)
            {
                self.errorHandler = task.next.errorHandler;
                task = task.next;
            }
        }
        
        if(self.errorHandler)
            self.errorHandler(value);
        return YES;
    }
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)finishedTask:(DCTask*)task result:(id)result
{
    if([self processError:task val:result])
        return;
    //a task was returned, so let's add it into the chain
    if([result isKindOfClass:[DCTask class]])
    {
        DCTask *rTask = result;
        rTask.next = task.next;
        task.next = rTask;
    }
    [self runTask:task.next param:result];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCTask*(^)(id))begin
{
    //__weak id weakSelf = self;
    return ^(DCTask*(^begin)(id)){
        DCTask *task = [DCTask new];
        self.next = task;
        task.work = begin;
        return task;
    };
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCTask*(^)(id))then
{
    return ^(DCTask*(^work)(id)){
        DCTask *task = [DCTask new];
        self.next = task;
        task.work = work;
        return task;
    };
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(DCTask*(^)(id))thenMain
{
    return ^(DCTask*(^work)(id)){
        DCTask *task = [DCTask new];
        self.next = task;
        task.isMain = YES;
        task.work = work;
        return task;
    };
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void(^)(id))catch
{
    return ^(void(^error)(NSError*)){
        self.errorHandler = error;
    };
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(DCTask*)new:(void (^)(void))beginBlock
{
    DCTask *task = [DCTask new];
    task.begin(^{
        beginBlock();
    });
    return task;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(DCTask*)newAsyncTask:(DCAsyncTask)asyncTask
{
    DCTask *task = [DCTask new];
    task.asyncTask = asyncTask;
    return task;
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
