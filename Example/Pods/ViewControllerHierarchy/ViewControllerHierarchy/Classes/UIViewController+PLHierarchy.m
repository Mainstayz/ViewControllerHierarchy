
#import "UIViewController+PLHierarchy.h"
#import <objc/runtime.h>

#ifdef __clang__
#if __has_feature(objc_arc)
#define HasARC
#endif
#endif
__attribute__((unused)) inline __attribute__((always_inline))
static void *Ivar_(id object, const char *name)
{
    Ivar ivar = class_getInstanceVariable(object_getClass(object), name);
    if (ivar)
#ifdef HasARC
        return (void *)&((char *)(__bridge void *)object)[ivar_getOffset(ivar)];
#else
    return (void *)&((char *)object)[ivar_getOffset(ivar)];
#endif
    return NULL;
}
#define IvarRef(object, name, type) \
((type *)Ivar_(object, #name))
#define Ivar(object, name, type) \
(*IvarRef(object, name, type))


@implementation UIViewController (PLHierarchy)
+ (UIViewController *)visibleViewControllerIfExist{
    return  [[UIApplication sharedApplication].delegate.window.rootViewController visibleViewControllerIfExist];
}
- (UIViewController *)visibleViewControllerIfExist {
    UIViewController *current = self;
check:{
    UIViewController *modalViewController = getChildModalViewController(current);
    if (!modalViewController && current.childViewControllers.count == 0) {
        goto finish;
    }else{
        if (modalViewController) {
            current = modalViewController;
        }else if (current.childViewControllers.count > 0){
            int total = 0;
            id temp = nil;
            for (UIViewController *vc in [[current.childViewControllers reverseObjectEnumerator] allObjects] ) {
                if (isAppeare(vc)) {
                    total ++;
                    if (total > 1) {
                        goto finish;
                    }else{
                        temp = vc;
                    }
                }
            }
            if (temp == nil) {
                goto finish;
            }
            current = temp;
        }
    }
    goto check;
}
finish:
    return current;
}
+ (UINavigationController *)topmostNavigationControllerIfExist{
    return [[UIApplication sharedApplication].delegate.window.rootViewController topmostNavigationControllerIfExist];
}
- (UINavigationController *)topmostNavigationControllerIfExist{
    UIViewController *current = [self visibleViewControllerIfExist];
    if (!current) {
        return nil;
    }
    while (![current isKindOfClass:[UINavigationController class]] && current){
        if (isRootViewController(current)) {
            current = nil;
            break;
        }
        if (getParentViewController(current)) {
            current = getParentViewController(current);
        }else{
            if (getModalSourceViewController(current)) {
                current = getModalSourceViewController(current);
            }else{
                current = nil;
            }
        }
    }
    return (UINavigationController *)current;
}
+ (NSString *)printHierarchy{
    return [[UIApplication sharedApplication].delegate.window.rootViewController printHierarchy];
}
- (NSString *)printHierarchy{
    NSMutableString *hierarchyString = [NSMutableString string];
    [hierarchyString appendString:@" "];
    @autoreleasepool{
        appendDescription(hierarchyString, self, 0);
    }
    return hierarchyString;
}

- (NSString *)descriptionForPrintingHierarchy{
    NSArray *status = @[@"disappeared",@"appearing",@"appeared",@"disappearing"];
    NSInteger flags = Ivar(self, _viewControllerFlags, NSInteger);
    NSString *selfStatus = status[flags&3];
    UIView *view = Ivar(self, _view, __strong UIView *);
    NSMutableString *viewDesc = nil;
    if (view) {
        viewDesc = [NSMutableString stringWithFormat:@"<%@ %p>",view.class,view];
        if (!view.window) {
            [viewDesc appendString:@" not in the window"];
        }
    }else{
        viewDesc = [NSMutableString stringWithString:@" (view not loaded) "];
    }
    
    return [NSMutableString stringWithFormat:@"<%@ %p>, state: %@, view: %@",self.class,self,selfStatus,viewDesc];
}
BOOL isAppeare(UIViewController *vc){
    NSInteger flags = Ivar(vc, _viewControllerFlags, NSInteger);
    return (flags&3) == 2;
}
BOOL isExplicitTransition(UIViewController *vc){
    NSInteger flags = Ivar(vc, _viewControllerFlags, NSInteger);
    return (flags >> 28 & 1);
}
UIViewController *getChildModalViewController(UIViewController *vc){
    return Ivar(vc, _childModalViewController, __strong UIViewController *);
}
UIViewController *getParentViewController(UIViewController *vc){
    return Ivar(vc, _parentViewController, __strong UIViewController *);
}
UIViewController *getModalSourceViewController(UIViewController *vc){
    return Ivar(vc, _modalSourceViewController, __strong UIViewController *);
}
BOOL isRootViewController(UIViewController *vc){
    NSInteger flags = Ivar(vc, _viewControllerFlags, NSInteger);
    return (flags >> 7 & 1);
}
NSMutableArray *getChildViewControllers(UIViewController *vc){
    return Ivar(vc, _childViewControllers, __strong NSMutableArray *);
}
void appendDescription(NSMutableString *string,UIViewController *vc,NSInteger level){
    NSMutableString  *previousStr = string;
    if (previousStr.length){
        [previousStr appendString:@"\n "];
    }
    if (vc.parentViewController){
        [previousStr appendString:tabsWithLevel(level)];
        [previousStr appendString:vc.descriptionForPrintingHierarchy];
    }else{
        if (isRootViewController(vc)){
            [previousStr appendString:vc.descriptionForPrintingHierarchy];
            [previousStr appendString:tabsWithLevel(level)];
        }else{
            if (level >= 2){
                NSInteger n = level - 1;
                do{
                    [previousStr appendString:@"   | "];
                    --n;
                }while (n);
            }
            [previousStr appendString:@"   + "];
            [previousStr appendString:vc.descriptionForPrintingHierarchy];
        }
    }
    NSArray *childViewController = [vc childViewControllers];
    [childViewController enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        appendDescription(previousStr, obj, level + 1);
    }];
    
    UIViewController *childModalVC = getChildModalViewController(vc);
    if (childModalVC) {
        appendDescription(previousStr, childModalVC, level + 1);
    }
}
NSString *tabsWithLevel(NSInteger level){
    NSMutableString * tabs = [NSMutableString string];
    if (level){
        NSInteger n = 1;
        do{
            [tabs appendString:@"   | "];
            n++;
        }while (n <= level);
    }
    return tabs;
}

@end

