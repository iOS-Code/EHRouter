//
//  AViewController.m
//  EHRouterDemo
//
//  Created by 岳琛 on 2018/12/25.
//  Copyright © 2018 KMF-Engineering. All rights reserved.
//

#import "AViewController.h"

@interface AViewController ()

@end

@implementation AViewController

+ (instancetype)createViewController:(id)parameters
{
    AViewController *a = [[AViewController alloc] init];
    a.title = [parameters valueForKey:@"info1"];
    return a;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
}

@end
