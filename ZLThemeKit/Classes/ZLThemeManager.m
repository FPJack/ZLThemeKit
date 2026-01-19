//
//  ZLThemeManager.m
//  ZLThemeKit
//
//  Created by admin on 2025/11/25.
//

#import "ZLThemeManager.h"
#import "ZLProxy.h"


#define kZLThemeKitKey @"kZLThemeKitKey"


NSString * const kThemeKitWillChangeNotification = @"kThemeKitWillChangeNotification";
NSString * const kThemeKitDidChangedNotification = @"kThemeKitDidChangedNotification";
ZLThemeValue const ZLThemeValueNormal = @"NORMAL";
ZLThemeValue const ZLThemeValueNight = @"NIGHT";

@interface ZLTableObj : NSObject
@property (nonatomic,strong)NSArray<NSString *> *themes;
/// key: 颜色id  :  value<主题:颜色值>
@property (nonatomic,strong)NSDictionary<NSString *,NSDictionary<NSString *,NSString *>*> *table;
@property (nonatomic,strong)NSMutableDictionary *cacheDic;
@end
@implementation ZLTableObj
- (instancetype)init
{
    self.cacheDic = NSMutableDictionary.dictionary;
    return self;
}
@end
@interface ZLThemeManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, UIColor *> *> *table;
@property (nonatomic,strong)ZLTableObj *colorTable;
@property (nonatomic,strong)ZLTableObj *imageTable;
@property (nonatomic,strong)ZLTableObj *alphaTable;
@property (nonatomic,strong,readwrite)NSArray<NSString *> *themes;
@property (nonatomic,copy,readwrite)NSString *currentTheme;
@end
@implementation ZLThemeManager
@synthesize currentTheme = _currentTheme;
+ (instancetype)share {
    static ZLThemeManager *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[ZLThemeManager alloc] init];
        sharedInstance.supportsStatusBar = YES;
        sharedInstance.supportsKeyboard = YES;
    });
    return sharedInstance;
}
- (void)setCurrentTheme:(NSString *)currentTheme {
    if ([currentTheme isEqualToString:_currentTheme]) return;
    _currentTheme = currentTheme;
    [NSUserDefaults.standardUserDefaults setObject:currentTheme forKey:kZLThemeKitKey];
//    [NSUserDefaults.standardUserDefaults synchronize];
    NSString *theme =  [NSUserDefaults.standardUserDefaults objectForKey:kZLThemeKitKey];
#if DEBUG
    NSLog(@"设置当前主题---%@",theme);
#endif
    [NSNotificationCenter.defaultCenter postNotificationName:kThemeKitWillChangeNotification object:currentTheme];
    [ZLProxy performSelector:@selector(changeTheme:) withObject:currentTheme];
}

- (void)loadFromColorFilePath:(NSString *)colorPath imageFilePath:(NSString *)imagePath alphaFilePath:(NSString *)alphaPath{
    [self loadColorFilePath:colorPath];
    [self loadImageFilePath:imagePath];
    [self loadAlphaFilePath:alphaPath];
}
- (void)loadColorFilePath:(NSString * _Nullable)colorFilePath{
    NSArray *array = [self parseTextToWordArray:colorFilePath];
    ZLTableObj *table = [self getTable:array valueConvert:^id (NSString *key,NSString *value) {
        return value;
    }];
    self.colorTable = table;
    self.themes = [array.firstObject copy];
    [self reload];
}
- (void)loadImageFilePath:(NSString * _Nullable)imageFilePath{
    NSArray *array = [self parseTextToWordArray:imageFilePath];
    ZLTableObj *table = [self getTable:array valueConvert:^NSString * (NSString *key,NSString *value) {
        return value;
    }];
    self.imageTable = table;
    [self reload];
}
- (void)loadAlphaFilePath:(NSString * _Nullable)alphaFilePath{
    NSArray *array = [self parseTextToWordArray:alphaFilePath];
    ZLTableObj *table = [self getTable:array valueConvert:^NSNumber * (NSString *key,NSString *value) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *number = [formatter numberFromString:value];
        return number ? number : @(1.0);
    }];
    self.alphaTable = table;
    [self reload];
}
- (void)refresh {
    [NSNotificationCenter.defaultCenter postNotificationName:kThemeKitWillChangeNotification object:self.currentTheme];
    [ZLProxy performSelector:@selector(changeTheme:) withObject:self.currentTheme];
}
- (void)loadFromDictionaryInfo:(ZLThemeSourceType *)themeSource {
    if (![themeSource isKindOfClass:NSDictionary.class]) return;
    self.themes = themeSource.allKeys;
    NSMutableDictionary *colorMap = NSMutableDictionary.dictionary;
    NSMutableDictionary *imageMap = NSMutableDictionary.dictionary;
    NSMutableDictionary *alphaMap = NSMutableDictionary.dictionary;
    [themeSource enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key1, NSDictionary<NSString *,NSDictionary<NSString *,NSString *> *> * _Nonnull obj1, BOOL * _Nonnull stop) {
        //key1 主题
        if (![obj1 isKindOfClass:NSDictionary.class]) return;
        [obj1 enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key2, NSDictionary<NSString *,NSString *> * _Nonnull obj2, BOOL * _Nonnull stop) {
            //key2 类别
            if (![obj2 isKindOfClass:NSDictionary.class]) return;
            [obj2 enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key3, id  _Nonnull obj3, BOOL * _Nonnull stop) {
                void (^block)(NSMutableDictionary *) = ^(NSMutableDictionary *dict) {
                    NSMutableDictionary *dic = dict[key3];
                    if (!dic) {
                        dic = NSMutableDictionary.dictionary;
                        [dict setValue:dic forKey:key3];
                    }
                    if ([obj3 isKindOfClass:NSString.class]) {
                        [dic setValue:[obj3 stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:key1];
                    }else if ([obj3 isKindOfClass:NSNumber.class]) {
                        [dic setValue:obj3 forKey:key1];
                    }
                };
                //key3 id
                if ([key2 isEqualToString:@"colors"]) {
                    block(colorMap);
                }else if ([key2 isEqualToString:@"alphas"]) {
                    block(alphaMap);
                }else if ([key2 isEqualToString:@"images"]) {
                    block(imageMap);
                }
            }];
        }];
    }];
    ZLTableObj *colorTable = ZLTableObj.new;
    colorTable.table = colorMap;
    self.colorTable = colorTable;
    ZLTableObj *alphaTable = ZLTableObj.new;
    alphaTable.table = alphaMap;
    self.alphaTable = alphaTable;
    ZLTableObj *imageTable = ZLTableObj.new;
    imageTable.table = imageMap;
    self.imageTable = imageTable;
    [self reload];
}

- (void)reload {
    NSString *theme = [NSUserDefaults.standardUserDefaults objectForKey:kZLThemeKitKey];
#if DEBUG
    NSLog(@"加载当前主题---%@",theme);
#endif
    if ([self.themes containsObject:theme]) {
        self.currentTheme = theme ? theme : ZLThemeValueNormal;
    }
}
- (void)updateTheme:(NSString *)theme {
    self.currentTheme = theme;
}
- (ZLThemeValue )currentTheme {
    if (!_currentTheme) {
        NSString *theme = [NSUserDefaults.standardUserDefaults objectForKey:kZLThemeKitKey];
        _currentTheme = theme ? theme : self.colorTable.themes.firstObject;
    }
    return _currentTheme;
}

- (ZLTableObj *)getTable:(NSArray<NSArray<NSString *> *> *)array valueConvert:(id(^)(NSString * key,NSString * value))block{
    ZLTableObj *table = ZLTableObj.new;
    table.themes = array.firstObject;
    NSMutableDictionary *mDic = NSMutableDictionary.dictionary;
    NSMutableArray *mArray = [array mutableCopy];
    if (mArray.count > 0) [mArray removeObjectAtIndex:0];
    [mArray enumerateObjectsUsingBlock:^(NSArray<NSString *> * _Nonnull arr, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = arr.lastObject;
        NSMutableDictionary *dic = NSMutableDictionary.dictionary;
        [arr enumerateObjectsUsingBlock:^(NSString*  _Nonnull subValue, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx < arr.count - 1) {
                if (block) {
                    NSString *subKey = table.themes[idx];
                    [dic setValue:block(subKey,subValue) forKey:subKey];
                }
            }
        }];
        [mDic setValue:dic forKey:key];
    }];
    table.table = mDic;
    return table;
}
+ (UIColor *)colorWithKey:(NSString *)key {
#if DEBUG
    NSParameterAssert(key);
#endif
    if (ZLThemeManager.share.pickerColorBlock) {
        return  ZLThemeManager.share.pickerColorBlock(key, ZLThemeManager.share.currentTheme);
    }
    
    if (![key isKindOfClass:NSString.class]) return nil;
    NSDictionary *dic =  [ZLThemeManager.share.colorTable.table valueForKey:key];
    NSString *color = dic[ZLThemeManager.share.currentTheme];
    UIColor *clr = [self colorFromString:color];
    return clr ? clr : UIColor.new;
}
+ (UIImage *)imageWithKey:(NSString *)key {
#if DEBUG
    NSParameterAssert(key);
#endif
    if (ZLThemeManager.share.pickerImageBlock) {
        return  ZLThemeManager.share.pickerImageBlock(key, ZLThemeManager.share.currentTheme);
        
    }
    
    
    if (![key isKindOfClass:NSString.class]) return nil;
    NSDictionary *dic =  [ZLThemeManager.share.imageTable.table valueForKey:key];
    NSString *imageName = dic[ZLThemeManager.share.currentTheme];
    NSArray *arr = [imageName componentsSeparatedByString:@"/"];
    UIImage *image;
    if (arr.count == 1) {
        image = [UIImage imageNamed:imageName];
    }else {
        Class cls = NSClassFromString(arr.firstObject);
        NSBundle *bundle = [NSBundle bundleForClass:cls];
        NSString *resourceBundleName = @"";
        if (arr.count == 2) {
            resourceBundleName = [bundle.executablePath componentsSeparatedByString:@"/"].firstObject;
        }else if (arr.count == 3) {
            resourceBundleName = arr[1];
        }
        NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:resourceBundleName ofType:@"bundle"]];
        image = [UIImage imageNamed:arr.lastObject inBundle:resourceBundle compatibleWithTraitCollection:nil];
    }
    if (!image) {
        NSLog(@"%@图片加载不出来",imageName);
    }
    return image ? image : UIImage.new;
}
+ (NSNumber *)alphaWithKey:(NSString *)key {
#if DEBUG
    NSParameterAssert(key);
#endif
    if (ZLThemeManager.share.pickerAlphaBlock) {
        return  @(ZLThemeManager.share.pickerAlphaBlock(key, ZLThemeManager.share.currentTheme));
    }
    if (![key isKindOfClass:NSString.class]) return nil;
    NSDictionary *dic =  [ZLThemeManager.share.alphaTable.table valueForKey:key];
    NSNumber *alpha = dic[ZLThemeManager.share.currentTheme];
    return alpha ? alpha : @(1.0);
}
+ (UIColor *)colorFromString:(NSString *)hexStr {
    hexStr = [hexStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if([hexStr hasPrefix:@"0x"]) {
        hexStr = [hexStr substringFromIndex:2];
    }
    if([hexStr hasPrefix:@"#"]) {
        hexStr = [hexStr substringFromIndex:1];
    }
    unsigned int hexInt = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner scanHexInt:&hexInt];
    return hexStr.length > 6 ? [self colorFromRGBA:hexInt] : [self colorFromRGB:hexInt];
}
- (NSArray<NSArray<NSString *> *> *)parseTextToWordArray:(NSString *)file {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:file.stringByDeletingPathExtension ofType:file.pathExtension];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
        #if DEBUG
        NSLog(@"%@\n\n%@",file,fileContents);
        #endif
    NSMutableArray *tempEntries = [[fileContents componentsSeparatedByString:@"\n"] mutableCopy];
    NSMutableArray *entries = [[NSMutableArray alloc] init];
    [tempEntries enumerateObjectsUsingBlock:^(NSString *  _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *trimmingEntry = [self stringByTrimmingTrailingCharactersInSet:NSCharacterSet.whitespaceCharacterSet string:entry];
        [entries addObject:trimmingEntry];
    }];
    [entries filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
    NSMutableArray *wordsArray = NSMutableArray.array;
    [entries enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *array = [self getWordTextArrayWithString:obj];
        if (array) {
            [wordsArray addObject:array];
        }
    }];
    return wordsArray;
}
- (NSArray<NSString *> *)getWordTextArrayWithString:(NSString *)string {
    NSArray *array = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
}
- (NSString *)stringByTrimmingTrailingCharactersInSet:(NSCharacterSet *)characterSet string:(NSString *)string {
    NSUInteger location = 0;
    NSUInteger length = [string length];
    unichar charBuffer[length];
    [string getCharacters:charBuffer];
    for (; length > 0; length--) {
        if (![characterSet characterIsMember:charBuffer[length - 1]]) {
            break;
        }
    }
    return [string substringWithRange:NSMakeRange(location, length - location)];
}
+(UIColor *)colorFromRGB:(NSUInteger )hex {
    return [UIColor colorWithRed:((CGFloat)((hex >> 16) & 0xFF)/255.0) green:((CGFloat)((hex >> 8) & 0xFF)/255.0) blue:((CGFloat)(hex & 0xFF)/255.0) alpha:1.0];
}

+(UIColor *)colorFromRGBA:(NSUInteger)hex {
    return [UIColor colorWithRed:((CGFloat)((hex >> 24) & 0xFF)/255.0) green:((CGFloat)((hex >> 16) & 0xFF)/255.0) blue:((CGFloat)((hex >> 8) & 0xFF)/255.0) alpha:((CGFloat)(hex & 0xFF)/255.0)];
}
@end
