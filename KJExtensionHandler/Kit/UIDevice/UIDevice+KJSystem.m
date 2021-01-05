//
//  UIDevice+KJSystem.m
//  KJExtensionHandler
//
//  Created by 杨科军 on 2020/10/23.
//  https://github.com/yangKJ/KJExtensionHandler

#import "UIDevice+KJSystem.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import "_KJMacros.h"
@implementation UIDevice (KJSystem)
@dynamic appCurrentVersion,appName,appIcon,deviceID,supportHorizontalScreen;
+ (NSString*)appCurrentVersion{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}
+ (NSString*)appName{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}
+ (NSString*)deviceID{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}
+ (UIImage*)appIcon{
    NSString *iconFilename = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFile"];
    NSString *name = [iconFilename stringByDeletingPathExtension];
    return [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:[iconFilename pathExtension]]];
}
+ (BOOL)supportHorizontalScreen{
    NSArray *temp = [NSBundle.mainBundle.infoDictionary objectForKey:@"UISupportedInterfaceOrientations"];
    if ([temp containsObject:@"UIInterfaceOrientationLandscapeLeft"] || [temp containsObject:@"UIInterfaceOrientationLandscapeRight"]) {
        return YES;
    }else{
        return NO;
    }
}
@dynamic launchImage,launchImageCachePath,launchImageBackupPath;
+ (UIImage*)launchImage{
    UIImage *lauchImage = nil;
    NSString *viewOrientation = nil;
    CGSize viewSize = [UIScreen mainScreen].bounds.size;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight){
        viewOrientation = @"Landscape";
    }else{
        viewOrientation = @"Portrait";
    }
    NSArray *imagesDictionary = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    for (NSDictionary *dict in imagesDictionary){
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        if (CGSizeEqualToSize(imageSize, viewSize)&& [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]]){
            lauchImage = [UIImage imageNamed:dict[@"UILaunchImageName"]];
        }
    }
    return lauchImage;
}
+ (NSString*)launchImageCachePath{
    NSString *bundleID = [NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"];
    NSString *path = nil;
    if (@available(iOS 13.0, *)) {
        NSString *libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        path = [NSString stringWithFormat:@"%@/SplashBoard/Snapshots/%@ - {DEFAULT GROUP}", libraryDirectory, bundleID];
    }else{
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        path = [[cachesDirectory stringByAppendingPathComponent:@"Snapshots"] stringByAppendingPathComponent:bundleID];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }
    return nil;
}
+ (NSString*)launchImageBackupPath{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cachesDirectory stringByAppendingPathComponent:@"ll_launchImage_backup"];
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{} error:nil];
    }
    return path;
}
/// 生成启动图
+ (UIImage*)kj_launchImageWithPortrait:(BOOL)portrait Dark:(BOOL)dark{
    return [self kj_launchImageWithStoryboard:@"LaunchScreen" Portrait:portrait Dark:dark];
}
/// 生成启动图，根据LaunchScreen名称、是否竖屏、是否暗黑
+ (UIImage*)kj_launchImageWithStoryboard:(NSString*)name Portrait:(BOOL)portrait Dark:(BOOL)dark{
    if (@available(iOS 13.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        window.overrideUserInterfaceStyle = dark?UIUserInterfaceStyleDark:UIUserInterfaceStyleLight;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:name bundle:nil];
    UIView *__view = storyboard.instantiateInitialViewController.view;
    __view.frame = [UIScreen mainScreen].bounds;
    CGFloat w = __view.frame.size.width;
    CGFloat h = __view.frame.size.height;
    if (portrait) {
        if (w > h) __view.frame = CGRectMake(0, 0, h, w);
    }else{
        if (w < h) __view.frame = CGRectMake(0, 0, h, w);
    }
    [__view setNeedsLayout];
    [__view layoutIfNeeded];
    UIGraphicsBeginImageContextWithOptions(__view.frame.size, NO, [UIScreen mainScreen].scale);
    [__view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *launchImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return launchImage;
}


/// 对比版本号
+ (BOOL)kj_comparisonVersion:(NSString*)version{
    if ([version compare:UIDevice.appCurrentVersion] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}
/// 获取AppStore版本号和详情信息
+ (NSString*)kj_getAppStoreVersionWithAppid:(NSString*)appid Details:(void(^)(NSDictionary*))block{
    __block NSString *appVersion = UIDevice.appCurrentVersion;
    if (appid == nil) return appVersion;
    NSString *urlString = [[NSString alloc] initWithFormat:@"http://itunes.apple.com/lookup?id=%@",appid];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_group_async(dispatch_group_create(), queue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSDictionary * dict = [json[@"results"] firstObject];
            appVersion = dict[@"version"];
            if (block) block(dict);
            dispatch_semaphore_signal(semaphore);
        }] resume];
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return appVersion;
}
/// 跳转到指定URL
+ (void)kj_openURL:(id)URL{
    if (URL == nil) return;
    if (![URL isKindOfClass:[NSURL class]]) {
        URL = [NSURL URLWithString:URL];
    }
    if ([[UIApplication sharedApplication] canOpenURL:URL]){
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
        }else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] openURL:URL];
#pragma clang diagnostic pop
        }
    }
}
/// 调用AppStore
+ (void)kj_skipToAppStoreWithAppid:(NSString*)appid{
    NSString *urlString = [@"http://itunes.apple.com/" stringByAppendingFormat:@"%@?id=%@",self.appName,appid];
    [self kj_openURL:urlString];
}
/// 调用自带浏览器safari
+ (void)kj_skipToSafari{
    [self kj_openURL:@"http://www.abt.com"];
}
/// 调用自带Mail
+ (void)kj_skipToMail{
    [self kj_openURL:@"mailto://admin@abt.com"];
}
/// 是否切换为扬声器
+ (void)kj_changeLoudspeaker:(bool)loudspeaker{
    if (loudspeaker) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }else{
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }
}
/// 保存到相册
static char kSavePhotosKey;
+ (void)kj_savedPhotosAlbumWithImage:(UIImage*)image Complete:(void(^)(BOOL success))complete{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    objc_setAssociatedObject(self, &kSavePhotosKey, complete, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo{
    void(^block)(BOOL success) = objc_getAssociatedObject(self, &kSavePhotosKey);
    if (block) block(error==nil?YES:NO);
}
/// 系统自带分享
+ (UIActivityViewController*)kj_shareActivityWithItems:(NSArray*)items ViewController:(UIViewController*)vc Complete:(void(^)(BOOL success))complete{
    if (items.count == 0) return nil;
    UIActivityViewController *__vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    if (@available(iOS 11.0, *)) {
        __vc.excludedActivityTypes = @[UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypeOpenInIBooks, UIActivityTypeMarkupAsPDF];
    }else if (@available(iOS 9.0, *)) {
        __vc.excludedActivityTypes = @[UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypeOpenInIBooks];
    }else{
        __vc.excludedActivityTypes = @[UIActivityTypeMessage, UIActivityTypeMail];
    }
    UIActivityViewControllerCompletionWithItemsHandler itemsBlock = ^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (complete) complete(completed);
    };
    __vc.completionWithItemsHandler = itemsBlock;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        __vc.popoverPresentationController.sourceView = vc.view;
        __vc.popoverPresentationController.sourceRect = CGRectMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height, 0, 0);
    }
    [vc presentViewController:__vc animated:YES completion:nil];
    return __vc;
}
/// 切换根视图控制器
+ (void)kj_changeRootViewController:(UIViewController*)vc Complete:(void(^)(BOOL success))complete{
    [UIView transitionWithView:kKeyWindow duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        BOOL oldState = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        kKeyWindow.rootViewController = vc;
        [UIView setAnimationsEnabled:oldState];
    }completion:^(BOOL finished) {
        if (complete) complete(finished);
    }];
}

@end
