//
//  ViewController.m
//  EHRouterDemo
//
//  Created by 岳琛 on 2018/12/25.
//  Copyright © 2018 KMF-Engineering. All rights reserved.
//

#import "ViewController.h"
#import "EHRouter/EHRouter.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)pusha:(UIButton *)sender
{
    [EHRouter registeRouterPattern:@"demo://Amodule/mall/detail" targetControllerName:@"AViewController"];
    [EHRouter startRouter:@"demo://Amodule/mall/detail?info1=RouterDemo&info2=测试跳转&info3=123456789"];
}

- (IBAction)pushb:(UIButton *)sender
{
    [EHRouter registeRouterPattern:@"demo://Bmodule/mall/list" targetControllerName:@"BViewController" handler:^(NSString * _Nonnull handlerTag, id  _Nonnull results) {
        NSLog(@"%s", __FUNCTION__);
    }];
    
    [EHRouter startRouter:@"demo://Bmodule/mall/list"];
}

- (IBAction)pushc:(UIButton *)sender
{
    
}

@end
