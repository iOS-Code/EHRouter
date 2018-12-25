//
//  EHRouter.m
//  EHRouterDemo
//
//  Created by 岳琛 on 2018/12/25.
//  Copyright © 2018 KMF-Engineering. All rights reserved.
//

#import "EHRouter.h"
#import <objc/runtime.h>

#pragma mark - [EHRouter]
@interface EHRouter ()

@property (strong, nonatomic) NSMutableDictionary *routes;

@end

@implementation EHRouter

#pragma mark - class method

+ (instancetype)defaultRouter
{
    static EHRouter * rout = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!rout) {
            rout = EHRouter.alloc.init;
        }
    });
    return rout;
}

+ (void)registeRouterPattern:(NSString *)routerPattern targetControllerName:(NSString *)targetControllerName
{
    [EHRouter registeRouterPattern:routerPattern targetControllerName:targetControllerName handler:nil];
}

+ (void)registeRouterPattern:(NSString *)routerPattern targetControllerName:(NSString *)targetControllerName handler:(EHRouterHandlerBlock)handlerBlock
{
    if (!routerPattern.length && !targetControllerName.length) {
        return;
    }
    
    [EHRouter.defaultRouter addRouterPattern:routerPattern targetControllerName:targetControllerName handler:handlerBlock];
}

+ (void)deregisteRouterPattern:(NSString *)routerPattern
{
    [EHRouter.defaultRouter removeRouterPattern:routerPattern];
}

+ (void)deregisteRouterPatternWithController:(Class)className
{
    [EHRouter.defaultRouter removeRouterPatternWithController:className];
}

+ (BOOL)startRouter:(NSString *)routerPattern
{
    if (!routerPattern.length) return NO;
    
    NSURL *url = [NSURL URLWithString:[routerPattern stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    return [EHRouter startRouterWithURL:url];
}

+ (BOOL)startRouterWithURL:(NSURL *)url
{
    if (!url) return NO;
    return [self analysisRouterPattern:url];
}

+ (BOOL)analysisRouterPattern:(NSURL *)url
{
    NSString * routerPattern = url.absoluteString;
    NSURLComponents * components = [NSURLComponents componentsWithString:routerPattern];
    NSString * scheme = components.scheme;
    
    // scheme 规则
    if (![scheme isEqualToString:@"demo"]) {
        NSLog(@"scheme校验失败");
        return NO;
    }
    
    if (components.host.length > 0 && (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound)) {
        NSString *host = [components.percentEncodedHost copy];
        components.host = @"/";
        components.percentEncodedPath = [host stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
    }
    
    NSString *path = [components percentEncodedPath];
    
    if (components.fragment != nil) {
        BOOL fragmentContainsQueryParams = NO;
        NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
        
        if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
            fragmentComponents.query = fragmentComponents.path;
        }
        
        if (fragmentComponents.queryItems.count > 0) {
            fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
        }
        
        if (fragmentContainsQueryParams) {
            components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
        }
        
        if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
            path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
        }
    }
    
    if (path.length > 0 && [path characterAtIndex:0] == '/') {
        path = [path substringFromIndex:1];
    }
    
    if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
        path = [path substringToIndex:path.length - 1];
    }
    
    // 获取目标
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary * queryParams = [NSMutableDictionary dictionary];
    
    for (NSURLQueryItem * item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    NSDictionary * params = queryParams.copy;
    return [EHRouter.defaultRouter pushTargetControllerWithRouterPattern:&routerPattern queryParams:&params];
}

#pragma mark - instance method

- (void)addRouterPattern:(NSString *)routerPattern targetControllerName:(NSString *)targetControllerName handler:(EHRouterHandlerBlock)handlerBlock
{
    if (!routerPattern.length && !targetControllerName.length) return;
    
    NSArray *pathComponents = [self pathComponentsFromRouterPattern:routerPattern];
    
    if (pathComponents.count > 1) {
        //for example:KMFProduct.AModule.Product.Detail
        NSString *components = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *routes = self.routes;
        
        if (![routes objectForKey:routerPattern]) {
            NSMutableDictionary *controllerHandler = [NSMutableDictionary dictionary];
            if (handlerBlock) {
                [controllerHandler setValue:[handlerBlock copy] forKey:targetControllerName];
                routes[components] = controllerHandler;
            } else {
                routes[components] = targetControllerName;
            }
        }
    }
}

- (void)removeRouterPattern:(NSString *)routerPattern
{
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromRouterPattern:routerPattern]];
    
    if (pathComponents.count >= 1) {
        NSString *components = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *routes = self.routes;
        
        if ([routes objectForKey:components]) {
            [routes removeObjectForKey:components];
        }
    }
}

- (void)removeRouterPatternWithController:(Class)class
{
    NSString *classString = NSStringFromClass(class);
    
    [self.routes enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *targetControllerName = nil;
        
        if ([obj isKindOfClass:[NSString class]]) {
            targetControllerName = (NSString *)obj;
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *controllerHandler = (NSDictionary *)obj;
            targetControllerName = controllerHandler.allKeys.firstObject;
        }
        
        if ([targetControllerName isEqualToString:classString]) {
            [self.routes removeObjectForKey:key];
            *stop = YES;
        }
    }];
}

#pragma mark - private method

- (NSArray *)pathComponentsFromRouterPattern:(NSString*)routerPattern
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    
    if ([routerPattern rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [routerPattern componentsSeparatedByString:@"://"];
        [pathComponents addObject:pathSegments[0]];
        
        routerPattern = pathSegments.lastObject;
        if (!routerPattern.length) {
            [pathComponents addObject:@"~"];
        }
    }
    
    for (NSString *pathComponent in [[NSURL URLWithString:routerPattern] pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    
    return [pathComponents copy];
}

- (BOOL)pushTargetControllerWithRouterPattern:(NSString **)routerPattern queryParams:(NSDictionary **)queryParams
{
    BOOL canOpen = NO;
    NSString *targetRouterPattern = *routerPattern;
    NSDictionary *targetQueryParams = *queryParams;
    NSArray *pathComponents = [self pathComponentsFromRouterPattern:targetRouterPattern];
    NSString *components = [pathComponents componentsJoinedByString:@"."];
    id routesValue = self.routes[components];
    
    NSString *targetControllerName = nil;
    NSDictionary *controllerHandler = nil;
    
    if ([routesValue isKindOfClass:[NSString class]]) {
        targetControllerName = (NSString *)routesValue;
    } else if ([routesValue isKindOfClass:[NSDictionary class]]) {
        controllerHandler = (NSDictionary *)routesValue;
        targetControllerName = controllerHandler.allKeys.firstObject;
    }
    
    Class targetClass = NSClassFromString(targetControllerName);
    SEL selector = NSSelectorFromString(@"createViewController:");
    
    if ([targetClass respondsToSelector:selector]) {
        UIViewController *targetController = [targetClass createViewController:targetQueryParams];
        if (targetController) {
            if (controllerHandler) {
                EHRouterHandlerBlock handlerBlock = [controllerHandler valueForKey:targetControllerName];
                if (handlerBlock) {
                    targetController.handlerBlock = handlerBlock;
                }
            }
            
            [EHRouter.defaultRouter.currentNavController pushViewController:targetController animated:YES];
            canOpen = YES;
        } else {
            NSLog(@"未找到相关类!");
        }
    } else {
        NSString *errorInfo = [NSString stringWithFormat:@"请让控制器遵守EHRouter的EHRouterProtocol协议"];
        NSLog(@"%@",errorInfo);
    }
    return canOpen;
}

#pragma mark - 其他
- (NSMutableDictionary *)routes
{
    if (!_routes) {
        _routes = [NSMutableDictionary dictionary];
    }
    return _routes;
}

@end


#pragma mark - [UINavigationController+EHRouter]

@interface UINavigationController (EHRouter)

@end

@implementation UINavigationController (JXBRouter)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        swizzleMethod(class, @selector(viewWillAppear:), @selector(aop_NavigationViewWillAppear:));
    });
}

- (void)aop_NavigationViewWillAppear:(BOOL)animation
{
    [self aop_NavigationViewWillAppear:animation];
    EHRouter.defaultRouter.currentNavController = self;
}

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end


#pragma mark - [UIViewController+EHRouter]
@implementation UIViewController (EHRouter)

static char kAssociatedParamsObjectKey;

- (EHRouterHandlerBlock)handlerBlock {
    return  objc_getAssociatedObject(self, &kAssociatedParamsObjectKey);
}

- (void)setHandlerBlock:(EHRouterHandlerBlock)handlerBlock {
    objc_setAssociatedObject(self, &kAssociatedParamsObjectKey, handlerBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
