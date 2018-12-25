//
//  EHRouter.h
//  EHRouterDemo
//
//  Created by 岳琛 on 2018/12/25.
//  Copyright © 2018 KMF-Engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 路由跳转的控制器需要遵守协议
 */
@protocol EHRouterProtocol <NSObject>

+ (instancetype)createViewController:(id)parameters;

@end


/**
 回调函数

 @param handlerTag 标记
 @param results 数据
 */
typedef void(^EHRouterHandlerBlock)(NSString *handlerTag, id results);


/**
 路由
 */
@interface EHRouter : NSObject

@property(nonatomic,weak) UINavigationController *currentNavController;

+ (instancetype)defaultRouter;

/**
 注册路由
 
 @param routerPattern 路由规则
 @param targetControllerName 目标控制器名称
 */
+ (void)registeRouterPattern:(NSString *)routerPattern targetControllerName:(NSString *)targetControllerName;


/**
 注册路由
 
 @param routerPattern 路由规则
 @param targetControllerName 目标控制器名称
 @param handlerBlock 回调block [handlerTag:回调标记, results:回调数据]
 */
+ (void)registeRouterPattern:(NSString *)routerPattern targetControllerName:(NSString *)targetControllerName handler:(EHRouterHandlerBlock)handlerBlock;


/**
 注销路由
 
 @param routerPattern 路由规则
 */
+ (void)deregisteRouterPattern:(NSString *)routerPattern;


/**
 注销路由
 
 @param className Class名称
 */
+ (void)deregisteRouterPatternWithController:(Class)className;


/**
 开始路由
 
 @param routerPattern 路由规则
 @return 是否可以路由
 */
+ (BOOL)startRouter:(NSString *)routerPattern;


/**
 开始路由
 
 @param URL 路由URL
 @return 是否可以路由
 */
+ (BOOL)startRouterWithURL:(NSURL *)URL;

@end



/**
  通过分类增加回调函数
 */
@interface UIViewController (EHRouter)

@property(nonatomic,copy) EHRouterHandlerBlock handlerBlock;

@end

NS_ASSUME_NONNULL_END
