//
//  BViewController.m
//  EHRouterDemo
//
//  Created by 岳琛 on 2018/12/25.
//  Copyright © 2018 KMF-Engineering. All rights reserved.
//

#import "BViewController.h"

@interface BViewController ()

@end

@implementation BViewController

+ (instancetype)createViewController:(id)parameters
{
    BViewController *b = [[BViewController alloc] init];
    return b;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
}

@end
