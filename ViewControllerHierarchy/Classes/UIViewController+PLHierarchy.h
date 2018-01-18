
#import <UIKit/UIKit.h>

@interface UIViewController (PLHierarchy)
+ (UIViewController *)visibleViewControllerIfExist;
- (UIViewController *)visibleViewControllerIfExist;
+ (UINavigationController *)topmostNavigationControllerIfExist;
- (UINavigationController *)topmostNavigationControllerIfExist;
+ (NSString *)printHierarchy;
- (NSString *)printHierarchy;
@end
