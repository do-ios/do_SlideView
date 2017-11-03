//
//  do_SlideView_Model.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SlideView_UIModel.h"
#import "doProperty.h"
#import "do_SlideView_UIView.h"
#import "doIEventCenter.h"

@interface do_SlideView_UIModel()<doIEventCenter>

@end

@implementation do_SlideView_UIModel

#pragma mark - 注册属性（--属性定义--）
/*
[self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];    
    //属性声明
	[self RegistProperty:[[doProperty alloc]init:@"allowGesture" :Bool :@"true" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"index" :Number :@"0" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"isAllCache" :Bool :@"false" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"looping" :Bool :@"false" :YES]];
	[self RegistProperty:[[doProperty alloc]init:@"templates" :String :@"无" :YES]];

}

- (void)eventOn:(NSString *)onEvent
{
    [((do_SlideView_UIView *)self.CurrentUIModuleView) eventName:onEvent :@"on"];
}

- (void)eventOff:(NSString *)offEvent
{
    [((do_SlideView_UIView *)self.CurrentUIModuleView) eventName:offEvent :@"off"];
}

@end
