//
//  KJImageJointVC.m
//  KJExtensionHandler
//
//  Created by 杨科军 on 2020/11/23.
//

#import "KJImageJointVC.h"

@interface KJImageJointVC ()

@end

@implementation KJImageJointVC

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat x,y;
    CGFloat sp = kAutoW(10);
    CGFloat w = (kScreenW-sp*2);
    CGFloat h = 105;
    CGFloat maxY = 0.;
    UIImage *image  = kGetImage(@"IMG_4931store_1024pt");
    UIImage *image2 = kGetImage(@"timg-2");
    UIImage *image3 = kGetImage(@"xxsf");
    NSArray *names = @[@"UIKit",@"vImage"];
    for (int k=0; k<names.count; k++) {
        x = sp;
        y = k*(h+sp)+sp+kSTATUSBAR_NAVIGATION_HEIGHT;
        UILabel *label = [UILabel kj_createLabel:^(id<KJQuickCreateHandle>  _Nonnull handle) {
            handle.kj_frame(x, y, w, 17).kj_add(self.view);
            handle.kj_background([UIColor.orangeColor colorWithAlphaComponent:0.2]);
            handle.kj_text(names[k]).kj_font([UIFont systemFontOfSize:16]).kj_textColor(UIColor.orangeColor);
        }];
        label.textAlignment = NSTextAlignmentLeft;
        UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(x, y+20, w, h-20)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = [UIColor.orangeColor colorWithAlphaComponent:0.1];
        [self.view addSubview:imageView];
        if (k==0) {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            UIImage *img = [image kj_moreJointLevelImage:image,image2,image3,nil];
            NSData *date = UIImagePNGRepresentation(img);
            NSLog(@"UIKitTime：%f，Data：%lu", CFAbsoluteTimeGetCurrent() - start,(unsigned long)date.length);
            imageView.image = img;
        }else if (k==1) {
            CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
            UIImage *img = [image kj_moreAccelerateJointLevelImage:image,image2,image3,nil];
            NSData *date = UIImagePNGRepresentation(img);
            NSLog(@"AccelerateTime：%f，Data：%lu", CFAbsoluteTimeGetCurrent() - start,(unsigned long)date.length);
            imageView.image = img;
        }
        maxY = imageView.maxY;
    }
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(sp, maxY+5*sp, w, w+2*sp)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor.orangeColor colorWithAlphaComponent:0.1];
    [self.view addSubview:imageView];
    __block NSInteger index = 3;
    __block void (^kChangeJointType)(void) = ^{
        index %= 5;
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        UIImage *img = [image kj_jointImageWithJointType:(KJJointImageType)index Size:imageView.size Maxw:imageView.width/7];
        NSData *date = UIImagePNGRepresentation(img);
        NSLog(@"JointImageTime：%f，Data：%lu", CFAbsoluteTimeGetCurrent() - start,(unsigned long)date.length);
        imageView.image = img;
        index++;
    };
    kChangeJointType();
    UIButton *button = [UIButton buttonWithType:(UIButtonTypeCustom)];
    button.frame = CGRectMake(sp, maxY+sp/2, 100, sp*3);
    button.backgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.3];
    button.layer.borderWidth = 1;
    button.layer.borderColor = UIColor.blueColor.CGColor;
    button.layer.masksToBounds = YES;
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button setTitleColor:UIColor.blueColor forState:(UIControlStateNormal)];
    [button setTitle:@"切换拼接类型" forState:(UIControlStateNormal)];
    [self.view addSubview:button];
    [button kj_addAction:^(UIButton * _Nonnull kButton) {
        kChangeJointType();
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
