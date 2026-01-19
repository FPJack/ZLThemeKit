//
//  ZLProxy.m
//  Pods
//
//  Created by admin on 2025/11/25.
//

#import "ZLProxy.h"
#import <objc/message.h>
#import "IGMTheme.h"
#import "ZLThemeManager.h"

static NSHashTable *_cache;

#define kCGColorTag 1
#define kAlphaTag 2
#define kImageTag 3
#define kColorTag 4
#define kAppearanceTag 5
#define kBlockPicker 6
#define kBlockskey @"ZLThemeKitBlocks"




@interface ZLPickerObj : NSObject
@property (nonatomic,copy)ZLBlockPicker blockPicker;
@property (nonatomic,strong)NSInvocation *invocation;
@property (nonatomic,assign)int tag;
@property (nonatomic,copy)NSString *themeId;
@property (nonatomic,strong)id argument;
@property (nonatomic,copy)NSString *identifier;
@end
@implementation ZLPickerObj
- (void)dealloc
{
    self.invocation = nil;
    self.argument = nil;
    self.themeId = nil;
}
@end
@interface ZLThemekitBKObj: NSObject
@property (nonatomic,copy)ZLThemeBlock block;
@property (nonatomic,assign)NSInteger idx;
@property (nonatomic,weak)NSObject *view;
@property (nonatomic,strong)ZLPickerObj *obj;
@end
@implementation ZLThemekitBKObj
@end


@interface ZLProxy()
@property (nonatomic,weak)NSObject* object;
@property (nonatomic,copy)NSString *theme;
+ (instancetype)wrapView:(NSObject *)obj;
@end


@implementation NSObject (GMTheme)
- (id<IGMThemeView>)themeKit {
    return (id<IGMThemeView>)[ZLProxy wrapView:self];
}
- (void)themeKit:(ZLThemeBlock)block {
    if (!block) return;
    block(self);
    ZLThemekitBKObj *obj = ZLThemekitBKObj.new;
    obj.block = [block copy];
    obj.idx = _cache.allObjects.count;
    obj.view = self;
    [_cache addObject:obj];
    [self._themeKitBKSet addObject:obj];
}

static const void *MyThemeKitId = &MyThemeKitId;
- (void)_setThemeKitId:(NSString *)themeKitId {
    if ([[self _themeKitId] isEqualToString:themeKitId]) return;
    objc_setAssociatedObject(self, MyThemeKitId, themeKitId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)_themeKitId {
    return objc_getAssociatedObject(self, MyThemeKitId);
}

- (void)_setThemeKitBKSet:(NSMutableSet *)set {
    objc_setAssociatedObject(self, @selector(_themeKitBKSet), set, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableSet *)_themeKitBKSet {
    NSMutableSet *set = objc_getAssociatedObject(self, @selector(_themeKitBKSet));
    if (!set) {
        set = [NSMutableSet set];
        [self _setThemeKitBKSet:set];
    }
    return set;
}
@end


@implementation ZLProxy
+ (UIColor *)colorWithKey:(NSString *)key {
    UIColor *color = [ZLThemeManager colorWithKey:key];
    if (color) [color _setThemeKitId:key];
    return color ? color : ZLThemeManager.share.defaultColor;
}
+ (UIImage *)imageWithKey:(NSString *)key {
    UIImage *image = [ZLThemeManager imageWithKey:key];
    if (image) [image _setThemeKitId:key];
    return image ? image : ZLThemeManager.share.defaultImage;
}
+ (NSNumber *)alphaWithKey:(NSString *)key {
    NSNumber *alpha = [ZLThemeManager alphaWithKey:key];
    if (alpha) [alpha _setThemeKitId:key];
    return alpha ? alpha : ZLThemeManager.share.defaultAlpha;
}
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cache = [NSHashTable weakObjectsHashTable];
    });
}
+ (instancetype)wrapView:(NSObject *)view {
    ZLProxy *proxy = ZLProxy.alloc;
    proxy.object = view;
    return proxy;
}
- (NSString *)theme {
    return ZLThemeManager.share.currentTheme;
}
+ (void)changeTheme:(ZLThemeValue )theme {
    if (ZLThemeManager.share.supportsStatusBar) {
        if ([theme isEqualToString:ZLThemeValueNight]) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        }else {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        }
    }
    CFTimeInterval start = CACurrentMediaTime();
    __block NSInteger count = 0;
    [[_cache.allObjects sortedArrayUsingComparator:^NSComparisonResult(ZLThemekitBKObj*  _Nonnull obj1, ZLThemekitBKObj*  _Nonnull obj2) {
            return obj1.idx > obj2.idx;
    }] enumerateObjectsUsingBlock:^(ZLThemekitBKObj*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        count += 1;
        if (obj.block) {
            if (obj.block) obj.block(obj.view);
        }else if(obj.obj){
            [self changeThemeWithObj:obj.view pickObj:obj.obj];
        }
    }];
    
    [NSNotificationCenter.defaultCenter postNotificationName:kThemeKitDidChangedNotification object:theme];
    CFTimeInterval end = CACurrentMediaTime();
#if DEBUG
    NSLog(@"主题切换view的个数:%ld---用时:%f秒",count,end-start);
#endif

}

+ (void)changeThemeWithObj:(NSObject*)view pickObj:(ZLPickerObj *)obj {
    [self changeKeyboardAppearce:view];
    ZLPickerObj* pickerObj = (ZLPickerObj *)obj;
    NSInvocation *invocation = pickerObj.invocation;
    int tag = pickerObj.tag;
    if (tag == kAlphaTag) {
         NSNumber *alpha = [ZLProxy alphaWithKey:pickerObj.themeId];
        CGFloat alphaValue = alpha.floatValue;
        [invocation setArgument:&alphaValue atIndex:2];
        [invocation invoke];
    }else if (tag == kCGColorTag){
        UIColor *color = [ZLProxy colorWithKey:pickerObj.themeId];
        CGColorRef cgColor = color.CGColor;
        [invocation setArgument:&cgColor atIndex:2];
        [invocation invoke];
    }else if (tag == kBlockPicker) {
        ZLBlockPicker block = pickerObj.blockPicker;
        if (block) {
            id blockReturnValue = block(ZLThemeManager.share.currentTheme);
            [invocation setArgument:&blockReturnValue atIndex:2];
            [invocation invoke];
        }else {
            id blockReturnValue;
            [invocation setArgument:&blockReturnValue atIndex:2];
            [invocation invoke];
        }
    }else if (tag == kAppearanceTag) {
        if (@available(iOS 13.0, *)) {
            ZLBlockPicker block = pickerObj.blockPicker;
            if (block) {
                UINavigationBarAppearance *appearance = block(ZLThemeManager.share.currentTheme);
                [invocation setArgument:&appearance atIndex:2];
                [invocation invoke];
            }else {
                UINavigationBarAppearance *appearance;
                [invocation setArgument:&appearance atIndex:2];
                [invocation invoke];
            }
        } else {
            // Fallback on earlier versions
        }
    } else {
        NSString *themeKitId = pickerObj.themeId;
        if (tag == kColorTag) {
             UIColor* argument = [ZLProxy colorWithKey:themeKitId];
            [invocation setArgument:&argument atIndex:2];
            [invocation invoke];
        }else if (tag == kImageTag) {
            UIImage* argument = [ZLProxy imageWithKey:themeKitId];
            [invocation setArgument:&argument atIndex:2];
            //括号外部调用有可能导致Image释放了导致坏内存崩溃
            [invocation invoke];
        }
    }
}
+ (void)changeKeyboardAppearce:(NSObject *)view {
    if (!ZLThemeManager.share.supportsKeyboard) return;
    NSString *theme = ZLThemeManager.share.currentTheme;
    if ([view isKindOfClass:UITextField.class]
        || [view isKindOfClass:UITextView.class]) {
        UIKeyboardAppearance apperance = [theme isEqualToString:ZLThemeValueNight] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        ((UITextField *)view).keyboardAppearance = apperance;
    }else if ([view isKindOfClass:UISearchBar.class]) {
        UIKeyboardAppearance apperance = [theme isEqualToString:ZLThemeValueNight] ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        if (@available(iOS 13.0, *)) {
            ((UISearchBar *)view).searchTextField.keyboardAppearance = apperance;
        } else {
            UITextField *searchField = [view valueForKey:@"_searchField"];
            searchField.keyboardAppearance = apperance;
        }
    }
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSString *aSelectorStr = NSStringFromSelector(aSelector);
    if (![aSelectorStr hasPrefix:@"set"]) {
        NSMethodSignature *sig  = [self.object methodSignatureForSelector:aSelector];
        return sig ? sig : [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }
    if ([aSelectorStr containsString:@"setAlpha:"] || [self.object isKindOfClass:CALayer.class]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }
    if ([aSelectorStr hasSuffix:@"AttributedText:"]
        || [aSelectorStr hasSuffix:@"Appearance:"]) {
        //block
        return [NSMethodSignature signatureWithObjCTypes:"v@:@?"];
    }
    NSMethodSignature *sig  = [self.object methodSignatureForSelector:aSelector];
    return sig ? sig : [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL aSelector = anInvocation.selector;
    if (![self.object respondsToSelector:aSelector]) {return;}
    NSString *aSelectorStr = NSStringFromSelector(aSelector);
    if (![aSelectorStr hasPrefix:@"set"]) {//get 方法直接object 调用
        [anInvocation invokeWithTarget:self.object];
        return;;
    }
    NSUInteger numberOfArguments = anInvocation.methodSignature.numberOfArguments;
    NSInteger state = -1;
    ZLPickerObj *pickerObj = ZLPickerObj.new;
    anInvocation.target = self.object;
    [ZLProxy changeKeyboardAppearce:self.object];
    //最后一个参数类型
    const char *lastArgType;
    for (NSUInteger i = 2; i < numberOfArguments; i++) { // 0:self, 1:_cmd
        const char *argType = [anInvocation.methodSignature getArgumentTypeAtIndex:i];
        if (strcmp(argType, "Q") == 0) {
            [anInvocation getArgument:&state atIndex:i];
        }
        if (i == numberOfArguments - 1) {
           lastArgType = [anInvocation.methodSignature getArgumentTypeAtIndex:i];
        }
    }
    if ([aSelectorStr containsString:@"setAlpha:"]) {
        __unsafe_unretained NSNumber *alpha;
        [anInvocation getArgument:&alpha atIndex:2];
        NSMethodSignature *sig = [self.object methodSignatureForSelector:aSelector];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.selector = aSelector;
        CGFloat alphaValue = alpha.floatValue;
        [invocation setArgument:&alphaValue atIndex:2];
        pickerObj.themeId = [alpha _themeKitId];
        pickerObj.tag = kAlphaTag;
        pickerObj.argument = alpha;
        invocation.target = self.object;
        [invocation invoke];
        anInvocation = invocation;
    } else if ([self.object isKindOfClass:CALayer.class]) {
        __unsafe_unretained UIColor *color;
        [anInvocation getArgument:&color atIndex:2];
        NSMethodSignature *sig = [self.object methodSignatureForSelector:aSelector];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.selector = aSelector;
        CGColorRef cgColor = color.CGColor;
        [invocation setArgument:&cgColor atIndex:2];
        pickerObj.themeId = [color _themeKitId];
        pickerObj.tag = kCGColorTag;
        pickerObj.argument = color;
        invocation.target = self.object;
        [invocation invoke];
        anInvocation = invocation;
    } else if ([self.object isKindOfClass:UINavigationBar.class]
               && strcmp(lastArgType, "@?") == 0
               && [aSelectorStr hasSuffix:@"Appearance:"]) {
        if (@available(iOS 13.0, *)) {
            __unsafe_unretained ZLBlockPicker appearancePicker;
            [anInvocation getArgument:&appearancePicker atIndex:2];
            UINavigationBarAppearance* appearance;
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.object methodSignatureForSelector:aSelector]];
            invocation.selector = aSelector;
            invocation.target = self.object;
            if (appearancePicker) {
                appearance = appearancePicker(ZLThemeManager.share.currentTheme);
                pickerObj.blockPicker = [appearancePicker copy];
                [invocation setArgument:&appearance atIndex:2];
                [invocation invoke];
            }else {
                [invocation setArgument:&appearance atIndex:2];
                [invocation invoke];
            }
            pickerObj.tag = kAppearanceTag;
            pickerObj.themeId = [NSString stringWithFormat:@"%f",[NSDate.date timeIntervalSince1970]];
            anInvocation = invocation;
        } else {
            // Fallback on earlier versions
        }
    }else if (strcmp(lastArgType, "@?") == 0) {
        __unsafe_unretained ZLBlockPicker blockPicker;
        NSUInteger index = numberOfArguments - 1;
        [anInvocation getArgument:&blockPicker atIndex:index];
        id blockReturnValue;
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self.object methodSignatureForSelector:aSelector]];
        invocation.selector = aSelector;
        invocation.target = self.object;
        if (blockPicker) {
            blockReturnValue = blockPicker(ZLThemeManager.share.currentTheme);
            pickerObj.blockPicker = [blockPicker copy];
            [invocation setArgument:&blockReturnValue atIndex:index];
            [invocation invoke];
        }else {
            [invocation setArgument:&blockReturnValue atIndex:index];
            [invocation invoke];
        }
        anInvocation = invocation;
        pickerObj.tag = kBlockPicker;
        pickerObj.themeId = [NSString stringWithFormat:@"%f",[NSDate.date timeIntervalSince1970]];
    }else {
        __unsafe_unretained id argument;
        [anInvocation getArgument:&argument atIndex:2];
        if (argument && [argument isKindOfClass:UIColor.class]) {
            pickerObj.tag = kColorTag;
            pickerObj.themeId = [argument _themeKitId];
            pickerObj.argument = argument;
            [anInvocation invoke];
        }else if (argument && [argument isKindOfClass:UIImage.class]) {
            pickerObj.tag = kImageTag;
            pickerObj.themeId = [argument _themeKitId];
            pickerObj.argument = argument;
            [anInvocation invoke];
        }
    }
    pickerObj.invocation = anInvocation;
    pickerObj.identifier = [NSString stringWithFormat:@"%ld--%@--%@",state,aSelectorStr,pickerObj.themeId ?: @""];
    
    __block ZLThemekitBKObj *existObj = nil;
    [self.object._themeKitBKSet enumerateObjectsUsingBlock:^(ZLThemekitBKObj*  _Nonnull bkObj, BOOL * _Nonnull stop) {
        if ([bkObj.obj.identifier isEqualToString:pickerObj.identifier])  {
            existObj = bkObj;
            *stop = YES;
        }
    }];
    if (existObj) [self.object._themeKitBKSet removeObject:existObj];
    
    ZLThemekitBKObj *obj = ZLThemekitBKObj.new;
    obj.block = nil;
    obj.idx = _cache.allObjects.count;
    obj.view = self.object;
    obj.obj = pickerObj;
    [self.object._themeKitBKSet addObject:obj];
    [_cache addObject:obj];
}

@end

UIColor* _Nullable kColorWithKey(NSString * _Nullable key) {
    return [ZLProxy colorWithKey:key];
}
UIImage* _Nullable kImageWithKey(NSString * _Nullable key) {
    return [ZLProxy imageWithKey:key];
}
NSNumber* _Nullable kAlphaWithKey(NSString * _Nullable key) {
    return [ZLProxy alphaWithKey:key];
}
