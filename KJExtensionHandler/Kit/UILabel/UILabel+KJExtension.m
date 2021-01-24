//
//  UILabel+KJExtension.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/9/24.
//  Copyright © 2020 杨科军. All rights reserved.
//  https://github.com/yangKJ/KJExtensionHandler

#import "UILabel+KJExtension.h"
#import <objc/runtime.h>
@implementation UILabel (KJExtension)
- (KJLabelTextAlignmentType)customTextAlignment{
    return (KJLabelTextAlignmentType)[objc_getAssociatedObject(self, @selector(customTextAlignment)) integerValue];
}
- (void)setCustomTextAlignment:(KJLabelTextAlignmentType)customTextAlignment{
    objc_setAssociatedObject(self, @selector(customTextAlignment), @(customTextAlignment), OBJC_ASSOCIATION_ASSIGN);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        method_exchangeImplementations(class_getInstanceMethod(self.class, @selector(drawTextInRect:)), class_getInstanceMethod(self.class, @selector(kj_drawTextInRect:)));
    });
    switch (customTextAlignment) {
        case KJLabelTextAlignmentTypeRight:
        case KJLabelTextAlignmentTypeRightTop:
        case KJLabelTextAlignmentTypeRightBottom:
            self.textAlignment = NSTextAlignmentRight;
            break;
        case KJLabelTextAlignmentTypeLeft:
        case KJLabelTextAlignmentTypeLeftTop:
        case KJLabelTextAlignmentTypeLeftBottom:
            self.textAlignment = NSTextAlignmentLeft;
            break;
        case KJLabelTextAlignmentTypeCenter:
        case KJLabelTextAlignmentTypeTopCenter:
        case KJLabelTextAlignmentTypeBottomCenter:
            self.textAlignment = NSTextAlignmentCenter;
            break;
        default:
            break;
    }
}
- (void)kj_drawTextInRect:(CGRect)rect{
    switch (self.customTextAlignment) {
        case KJLabelTextAlignmentTypeRight:
        case KJLabelTextAlignmentTypeLeft:
        case KJLabelTextAlignmentTypeCenter:
            [self kj_drawTextInRect:rect];
            break;
        case KJLabelTextAlignmentTypeBottomCenter:
        case KJLabelTextAlignmentTypeLeftBottom:
        case KJLabelTextAlignmentTypeRightBottom:{
            CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
            textRect.origin = CGPointMake(textRect.origin.x, -CGRectGetMaxY(textRect)+rect.size.height);
            [self kj_drawTextInRect:textRect];
        }
            break;
        default:{
            CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
            [self kj_drawTextInRect:textRect];
        }
            break;
    }
}
/// 获取宽度
- (CGFloat)kj_calculateWidth{
    self.lineBreakMode = NSLineBreakByCharWrapping;
    CGSize size = [UILabel kj_calculateLabelSizeWithTitle:self.text font:self.font constrainedToSize:CGSizeMake(MAXFLOAT, self.frame.size.height) lineBreakMode:NSLineBreakByCharWrapping];
    return ceil(size.width);
}
/// 获取高度
- (CGFloat)kj_calculateHeightWithWidth:(CGFloat)width{
    self.numberOfLines = 0;
    self.lineBreakMode = NSLineBreakByCharWrapping;
    CGSize size = [UILabel kj_calculateLabelSizeWithTitle:self.text font:self.font constrainedToSize:CGSizeMake(width, MAXFLOAT) lineBreakMode:NSLineBreakByCharWrapping];
    return ceil(size.height);
}
/// 获取高度，指定行高
- (CGFloat)kj_calculateHeightWithWidth:(CGFloat)width OneLineHeight:(CGFloat)height{
    CGFloat newHeight = [self kj_calculateHeightWithWidth:width];
    return newHeight * height / self.font.lineHeight;
}
/// 获取文字尺寸
+ (CGSize)kj_calculateLabelSizeWithTitle:(NSString*)title font:(UIFont*)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode{
    if (title.length == 0) return CGSizeZero;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = lineBreakMode;
    CGRect frame = [title boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font,NSParagraphStyleAttributeName:paragraph} context:nil];
    return frame.size;
}

@end
