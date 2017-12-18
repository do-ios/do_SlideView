
//
//  do_SlideView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SlideView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doIPage.h"
#import "doUIContainer.h"
#import "doISourceFS.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doIOHelper.h"

#define SET_FRAME(CONTENT) x = CONTENT.frame.origin.x + increase;if(x < 0) x = pageWidth * 2;if(x > pageWidth * 2) x = 0.0f;[CONTENT setFrame:CGRectMake(x,CONTENT.frame.origin.y,CONTENT.frame.size.width,CONTENT.frame.size.height)]

#define MIN_VALUE 0


@interface do_SlideView_UIView ()<UIScrollViewDelegate>
@property (nonatomic , assign) int currentPage;
@end


@implementation do_SlideView_UIView
{
@private
    id<doIListData> _dataArray;
    BOOL _isLooping;
    NSMutableArray *_pages;
    int _currentPage;
    int _positionPage;
    
    doInvokeResult * _invokeResult;
    int lastPage;
    
    NSMutableDictionary *_moudles;
    
    BOOL isDrag;
    
    BOOL _isAllCache;
    
    NSTimer *loopTime;
    
    int _direction;
    
    BOOL _allowGesture;
    
    UITapGestureRecognizer *_tap;
    
    NSMutableDictionary *_jsonDatas;
}
@synthesize currentPage = _currentPage;
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _isLooping = NO;
    _pages = [NSMutableArray array];
    _currentPage = 0;
    lastPage = -99;
    
    _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    
    _moudles = [NSMutableDictionary dictionary];
    
    _jsonDatas = [NSMutableDictionary dictionary];

    _isAllCache = YES;
    
    self.scrollsToTop = NO;
    
    self.scrollEnabled = YES;
    
    _allowGesture = YES;

    _direction = 1;
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    doInvokeResult* invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    NSDictionary *dict = @{@"index":@(_currentPage)};
    [invokeResult SetResultNode:dict];
    [_model.EventCenter FireEvent:@"touch":invokeResult];
}

- (void)change_templates:(NSString *)newValue
{
    if (!newValue || [newValue isEqualToString:@""]) {
        return;
    }
    _pages = [NSMutableArray array];
    [_pages addObjectsFromArray:[newValue componentsSeparatedByString:@","]];
    
    [self clearModules];
    _moudles = [NSMutableDictionary dictionary];
}

- (void)change_isAllCache:(NSString *)newValue
{
    _isAllCache = YES;
}

- (void)change_allowGesture:(NSString *)newValue
{
    self.scrollEnabled = [newValue boolValue];
    _allowGesture = [newValue boolValue];
}

- (void)clearModules
{
    [_moudles.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj respondsToSelector:@selector(OnDispose)]) {
            [obj OnDispose];
        }
    }];
    [_moudles removeAllObjects];
}
- (NSArray *)getDisplayContent
{
    NSInteger c = [_dataArray GetCount]>3?3:[_dataArray GetCount];
    if ([_dataArray GetCount]>0) {
        self.currentPage = self.currentPage;
    }
    NSMutableArray *a = [NSMutableArray array];
    if (!_isLooping) {
        if (_currentPage == MIN_VALUE) {
            for (NSInteger i =0;i<c;i++) {
                [a addObject:@(i)];
            }
        }else if (_currentPage == [_dataArray GetCount]-1){
            for (NSInteger i = [_dataArray GetCount]-1;i>=0;i--) {
                [a addObject:@(i)];
                if (a.count>=3) {
                    break;
                }
            }
            a = [NSMutableArray arrayWithArray:[[a reverseObjectEnumerator] allObjects]];
        }
    }else{
        if (_currentPage == MIN_VALUE) {
            int maxValue = [_dataArray GetCount]-1;
            a = [NSMutableArray arrayWithObjects:@(maxValue),@(MIN_VALUE),@(MIN_VALUE+1), nil];
        }else if (_currentPage == [_dataArray GetCount]-1){
            int maxValue = [_dataArray GetCount]-1;
            a = [NSMutableArray arrayWithObjects:@(maxValue-1),@(maxValue),@(0), nil];
        }
    }
    
    if (_currentPage>MIN_VALUE && _currentPage<[_dataArray GetCount]-1) {
        a = [NSMutableArray arrayWithObjects: @(_currentPage-1),@(_currentPage),@(_currentPage+1), nil];
    }
    
    if (c==1) {
        a = [NSMutableArray arrayWithObjects:@(0), nil];
    }
    if (c<3) {
        [self setContentSize:CGSizeMake(self.frame.size.width*c, self.frame.size.height)];
        self.contentOffset = CGPointMake(self.frame.size.width*abs(self.currentPage), 0);
    }
    return a;
}

- (void)change_index:(NSString *)newValue
{
    int tempIndex = [newValue intValue];
    if ([_dataArray GetCount] == 0) {
        return;
    }
    
    //传过来的数据合法
    if (tempIndex < 0) {
        tempIndex = 0;
    }
    if (tempIndex >= [_dataArray GetCount]) {
        tempIndex = [_dataArray GetCount] - 1;
    }

    if (tempIndex != _currentPage) {
        [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%d",tempIndex]];
        _currentPage = tempIndex;
        [self resetView:[self getDisplayContent]];
        [self fireEvent:@(_currentPage)];
    }
}

- (void)setCurrentPage:(int)page
{
    if ([_dataArray GetCount]>0) {
        _currentPage = page;
    }
}

- (int)currentPage
{
    int page = _currentPage;
    if (_currentPage < 0) {
        page = 0;
    }
    if ([_dataArray GetCount]>0) {
        if (_currentPage >= [_dataArray GetCount]) {
            page = [_dataArray GetCount]-1;
        }
    }else
        page = 0;
    
    return page;
}

- (void)fireEvent:(NSNumber *)index
{
    if (lastPage == _currentPage) {
        return;
    }
    [_model SetPropertyValue:@"index" :[index stringValue]];
    [_invokeResult SetResultInteger:[index intValue]];
    [_model.EventCenter FireEvent:@"indexChanged":_invokeResult];
    
    lastPage = _currentPage;
}

- (void)change_looping:(NSString *)newValue
{
    _isLooping = [newValue boolValue];
}


- (void)initialization{
    [self setDelegate:self];
    [self setPagingEnabled:YES];
    [self setShowsHorizontalScrollIndicator:NO];
    [self setShowsVerticalScrollIndicator:NO];
    
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.canCancelContentTouches = NO;
}

#pragma mark -

#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDrag = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = CGRectGetWidth(self.frame);
    int page = (scrollView.contentOffset.x/pageWidth)+.5;
    if (page!=_positionPage) {
        if (!_isLooping) {
            if (page<0||page>[_dataArray GetCount]-1) {
                return;
            }
        }
        int direction = 0;
        if (page>_positionPage) {
            direction = 1;
            ++_currentPage;
        }else if(page<_positionPage){
            direction = -1;
            --_currentPage;
        }
        _positionPage = page;
        [self prepareReuseView:direction];
    }
}

- (void)prepareReuseView:(int)direction
{
    if (direction == 0) {
        return;
    }
    CGFloat pageWidth = CGRectGetWidth(self.frame);
    CGFloat pageHeight = CGRectGetHeight(self.frame);
    
    for (UIView *obj in self.subviews) {
        CGFloat x = CGRectGetMinX(obj.frame);
        CGFloat offset = x-_positionPage*pageWidth;
        if (fabs(offset/pageWidth) >= 1.95) {
            if ([self getValideNum:(int)(_currentPage+direction)]<0&&!_isLooping) {
                break;
            }
            [obj removeFromSuperview];
            
            UIView *v = [self getPage:[self getValideNum:[self genetatePrePage:direction :(int)(_currentPage+direction)]]];
            if (!v) {
                break;
            }
            v.frame = CGRectMake((_positionPage+direction)*pageWidth, 0, pageWidth, pageHeight);
            [self addSubview:v];
            
            break;
        }
    }
    _currentPage = [self genetatePrePage:direction :(int)_currentPage];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //    for (UIView *v in self.subviews) {
    //        [self setModleData:v :_currentPage];
    //    }
    [self scrollEnd];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x/CGRectGetWidth(scrollView.frame)>19000) {
        [self change_index:[@(_currentPage) stringValue]];
        [self restoreDragable];
    }
    [self scrollEnd];
}

- (void)scrollEnd
{
    [self fireEvent:@(_currentPage)];
    [self restoreDragable];
}

- (void)restoreDragable
{
    self.scrollEnabled = _allowGesture;
    isDrag=NO;
}

- (BOOL)setModelData:(UIView *)v :(int)index
{
    doUIModule *module = [(id<doIUIModuleView>)v GetModel];
    NSDictionary *dict = [_dataArray GetData:index];
    int num1 = [[dict objectForKey:@"template"] intValue];
    if (num1 <= MIN_VALUE || num1 >= [_dataArray GetCount]) {
        return NO;
    }
    [module SetModelData:dict];
    return YES;
}

- (int)genetatePrePage:(BOOL)isRight  :(int)page
{
    if (_isLooping) {
        if (page < MIN_VALUE) {
            page = ([_dataArray GetCount])-abs((page)%([_dataArray GetCount]));
        }else if(page > [_dataArray GetCount]-1){
            page = abs((page)%([_dataArray GetCount]));
        }
    }else{
        if (page < MIN_VALUE) {
            page = 0;
        }else if(page > [_dataArray GetCount]-1){
            page = [_dataArray GetCount]-1;
        }
    }
    return page;
}

- (void) bindItems: (NSArray*) parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneValue:_dictParas :@"data"];
    
    @try {
        if (_address == nil || _address.length <= 0)
            [NSException raise:@"doSlideView" format:@"未指定相关的SlideView data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doListView" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])
        {
            if(_dataArray!= bindingModule)
                _dataArray = bindingModule;
            if ([_dataArray GetCount]>0) {
                [self refreshItems:parms];
            }
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
    }

}

- (void)refreshItems: (NSArray*) parms
{
    if ([_dataArray GetCount] <= 1) {//只有一个cell时，禁止滑动
        self.scrollEnabled = NO;
    }
    else
    {
        self.scrollEnabled = _allowGesture;
    }
    // 需要调用，避免设计器设置index后，后来调用bindItems
    [self change_index:[_model GetPropertyValue:@"index"]];
    [self resetView:[self getDisplayContent]];
}

- (void)resetView:(NSArray *)a
{
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if ([_dataArray GetCount]<=0) {
        [self setContentOffset:CGPointMake(0, 0)];
        [self setContentSize:CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        _positionPage = 0;
        return;
    }
    
    if (_isLooping) {
        [self setContentSize:CGSizeMake(width*20000, height)];
        _positionPage = 10000;
    }else{
        [self setContentSize:CGSizeMake(width*[_dataArray GetCount], height)];
        _positionPage = 0;
    }
    
    for (int i = 0;i<a.count;i++) {
        int tmp = [[a objectAtIndex:i] intValue];
        UIView *view = [self getPage:[self getValideNum:tmp]];
        if (view) {
            CGFloat x = 0;
            if (_isLooping) {
                x = (_positionPage+i)*width;
            }else
                x = (_positionPage+tmp)*width;
            
            //bug:proddev-5413
            dispatch_async(dispatch_get_main_queue(), ^{
                view.frame = CGRectMake(x, 0, width, height);
            });
            [self addSubview:view];
        }
    }
    if (_isLooping) {
        _positionPage += [a indexOfObject:@(_currentPage)];
    }else
        _positionPage += [[a objectAtIndex:[a indexOfObject:@(_currentPage)]] intValue];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setContentOffset:CGPointMake((_positionPage)*width, 0) animated:NO];
    });
}

- (int)getValideNum:(int)num
{
    if (!_isLooping) {
        if (num < MIN_VALUE || num >= [_dataArray GetCount]) {
            return -1;
        }
    }
    return num;
}

- (UIView *)getPage:(int)num
{
    NSString *discription = [NSString stringWithFormat:@"模板%i不存在",num];
    if (num < MIN_VALUE || num >= [_dataArray GetCount]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :discription];
        return [[UIView alloc] initWithFrame:self.bounds];
    }
    NSMutableDictionary *dict = (NSMutableDictionary *)[_dataArray GetData:num];
    int num1 = [[dict objectForKey:@"template"] intValue];
    if (num1 < MIN_VALUE || num1 >= [_pages count]) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :discription];
        return [[UIView alloc] initWithFrame:self.bounds];
    }
    
    NSString *modelKey = [@(num) stringValue];
    
    NSMutableDictionary *data = [_jsonDatas objectForKey:modelKey];
    BOOL isRecreate = YES;
    BOOL isRedraw = YES;
    if (data) {
        int num2 = [[data objectForKey:@"template"] intValue];
        if (![data isEqualToDictionary:dict]) {
            if (num1==num2) {
                isRecreate = NO;
            }else
                isRecreate = YES;
        }else{
            isRecreate = NO;
            isRedraw = NO;
        }
    }else
        data = [NSMutableDictionary dictionary];

    data = [dict mutableCopy];
    [_jsonDatas setObject:data forKey:modelKey];

    UIView *v = [self getAllCacheView:num1 index:num :dict :isRecreate :isRedraw];

    return v;
}

- (UIView *)getAllCacheView:(int)num1 index:(int)num :(NSMutableDictionary *)dict :(BOOL)isRecreate :(BOOL)isRedraw
{
    NSString* fileName = [_pages objectAtIndex:num1];
    if (fileName) {
        fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    }else
        fileName = @"";
    NSString *discription = [NSString stringWithFormat:@"模板不存在 :%@",fileName];
    if ([fileName hasSuffix:@"/"] || fileName.length==0) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :discription];
        return [[UIView alloc] initWithFrame:self.bounds];
    }
    NSString *fileFullName = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :fileName];

    if (![doIOHelper ExistFile:fileFullName]){
        [[doServiceContainer Instance].LogEngine WriteError:nil :discription];
        return [[UIView alloc] initWithFrame:self.bounds];
    }

    doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:fileName];
    id<doIPage> pageModel = _model.CurrentPage;
    doUIModule* module;
    NSString *modelKey = [@(num) stringValue];
    UIView *view = [_moudles objectForKey:modelKey];
    
    if (isRecreate) {
        if (view) {
            if ([view respondsToSelector:@selector(OnDispose)]) {
                [(id<doIUIModuleView>)view OnDispose];
            }
            [_moudles removeObjectForKey:modelKey];
            view = nil;
        }
    }
    
    if (!view) {
        @try {
            doUIContainer *container = [[doUIContainer alloc] init:pageModel];
            [container LoadFromFile:source:nil:nil];
            module = container.RootView;
            [container LoadDefalutScriptFile:fileName];
        } @catch (NSException *exception) {
            return [[UIView alloc] initWithFrame:self.bounds];
        }

        view = (UIView*)(((doUIModule*)module).CurrentUIModuleView);
    }

    if (isRedraw) {
        if (!module) {
            module = [(id<doIUIModuleView>)view GetModel];
        }
        id<doIUIModuleView> modelView =((doUIModule*) module).CurrentUIModuleView;
        [module SetModelData:dict];
        [modelView OnRedraw];
    }

    [_moudles setObject:view forKey:modelKey];
    
    return view;
}

//销毁所有的全局对象
- (void) OnDispose
{
    [_jsonDatas removeAllObjects];
    _jsonDatas = nil;
    _model = nil;
    [self removeGestureRecognizer:_tap];
    _tap = nil;
    [(doModule*)_dataArray Dispose];
    //自定义的全局属性
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self clearModules];
    _moudles = nil;
    [_pages removeAllObjects];
    _pages = nil;
    _invokeResult = nil;
    [self stop];
}
//实现布局`
- (void) OnRedraw
{
    //实现布局相关的修改
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
    [self initialization];
    
    NSLog(@"OnRedraw");
}

#pragma mark - auto scroll
- (void)startLoop:(NSArray *)parms
{
    [self stop];
 
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    NSTimeInterval interval = ([doJsonHelper GetOneFloat:_dictParas :@"interval" :300])/1000;

    [self performSelectorInBackground:@selector(start:) withObject:@(interval)];
}
- (void)start:(NSNumber *)interval
{
    [NSThread sleepForTimeInterval:[interval doubleValue]];
    loopTime = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSince1970:0] interval:[interval doubleValue] target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:loopTime forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];

}
- (void)stopLoop:(NSArray *)parms
{
    [self stop];
}
- (void)stop
{
    if (loopTime) {
        [loopTime invalidate];
        loopTime = nil;
    }
}
- (void)autoScroll
{
    if (isDrag) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        CGPoint p = self.contentOffset;
        CGFloat x = 0;
        CGFloat pageWidth = self.frame.size.width;
        CGFloat contentSize = self.contentSize.width;
        
        if(p.x==0){
            _direction = 1;
            x = pageWidth*(_currentPage+1);
        }else if((contentSize-p.x)/pageWidth>.95&&(contentSize-p.x)/pageWidth<=1.05){
            _direction = -1;
            x = pageWidth*(_currentPage-1);
        }else
            x = p.x+pageWidth*_direction;
        self.scrollEnabled = NO;
        //    isDrag=YES;
        x = round(x/pageWidth)*pageWidth;
        NSValue *value = [NSValue valueWithCGRect:CGRectMake(x, 0, pageWidth, CGRectGetHeight(self.frame))];
        [self scrollRectToVisible:[value CGRectValue] animated:YES];
    });
}

- (void)getView:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //构建_invokeResult的内容
    NSString* pageID = [doJsonHelper GetOneText: _dictParas : @"index" : @""];
    if (!pageID || pageID.length==0) {
        pageID = [@(_currentPage) stringValue];
    }
    doInvokeResult *invokeResult = [parms objectAtIndex:2];
    
    doUIModule *module = nil;
    id pageValue = [_moudles objectForKey:pageID];
    if (pageValue) {
        module = [(id<doIUIModuleView>)[_moudles objectForKey:pageID] GetModel];
        if (module) {
            [invokeResult SetResultText:module.UniqueKey];
        }else
            [invokeResult SetResultText:@""];
    }else
        [invokeResult SetResultText:@""];
}
#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */

#pragma mark -
#pragma mark - 同步异步方法的实现
/*
 1.参数节点
 doJsonNode *_dictParas = [parms objectAtIndex:0];
 在节点中，获取对应的参数
 NSString *title = [_dictParas GetOneText:@"title" :@"" ];
 说明：第一个参数为对象名，第二为默认值
 
 2.脚本运行时的引擎
 id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
 
 同步：
 3.同步回调对象(有回调需要添加如下代码)
 doInvokeResult *_invokeResult = [parms objectAtIndex:2];
 回调信息
 如：（回调一个字符串信息）
 [_invokeResult SetResultText:((doUIModule *)_model).UniqueKey];
 异步：
 3.获取回调函数名(异步方法都有回调)
 NSString *_callbackName = [parms objectAtIndex:2];
 在合适的地方进行下面的代码，完成回调
 新建一个回调对象
 doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
 填入对应的信息
 如：（回调一个字符串）
 [_invokeResult SetResultText: @"异步方法完成"];
 [_scritEngine Callback:_callbackName :_invokeResult];
 */

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResults
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResults];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

#pragma mark - event
- (void)eventName:(NSString *)event :(NSString *)type
{
    if ([event isEqualToString:@"touch"]) {
        if ([type isEqualToString:@"on"] && _allowGesture) {
            [self addGestureRecognizer:_tap];
        }else
            [self removeGestureRecognizer:_tap];
    }
}

@end
