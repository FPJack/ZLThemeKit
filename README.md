# ZLThemeKit
一个iOS多主题切换的库，支持运行时切换主题，支持多种主题资源类型，使用简单方便。


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ZLThemeKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:




```ruby
pod 'ZLThemeKit'
```

颜色配置文件格式
```txt
NORMAL   NIGHT    RED
#ffffff  #343434  #fafafa BG
#aaaaaa  #313131  #aaaaaa SEP
#0000ff  #ffff00  #fa0000 TINT
#000000  #00ffff  #ff00ff TEXT
#0000ff  #00ffff  #ff00ff RICH
#ffffff  #444444  #ff00ff BAR
#f0f0f0  #222222  #dedede HIGHLIGHTED
```

图片配置文件格式
```txt
NORMAL            NIGHT           RED
night1            normal          image_red   image2
image_blue        image_red       night       image3
normal            image_red       image_red   image4
normal            image_red       image_red   image5
normal            image_red       image_red   image6
```


通过txt文件加载颜色配置
```objc
    ZLThemeManager.share loadColorFilePath:@"GMColorTable.txt"];
```

通过txt文件加载图片配置
```objc
    ZLThemeManager.share loadImageFilePath:@"GMImageTable.txt"];
```

通过plist.info文件加载主题配置（txt还是plist.info加载二选一）
```objc
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Configure" ofType:@"plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    [ZLThemeManager.share loadFromDictionaryInfo:plistData];
```
       
    通过themeKit消息转发对象配置各种view的颜色、图片等属性
```objc
    TableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableCell" forIndexPath:indexPath];
    cell.label.text = [NSString stringWithFormat:@"This is row %ld", (long)indexPath.row];
    cell.label.themeKit.textColor = kColorWithKey(@"TEXT");
    cell.contentView.themeKit.backgroundColor = kColorWithKey(@"BG");
    cell.imgView.themeKit.image = kImageWithKey(@"image2");
    cell.progress.themeKit.tintColor = kColorWithKey(@"TINT");
    [cell.button.themeKit setImage:kImageWithKey(@"image3") forState:UIControlStateNormal];
    [cell.button.themeKit setImage:kImageWithKey(@"image4") forState:UIControlStateSelected];
```   
    
    修改主题
```objc
    [ZLThemeManager.share updateTheme:@"NORMAL"];
```   
   
          

## Author

fanpeng, 2551412939@qq.com

## License

ZLThemeKit is available under the MIT license. See the LICENSE file for more info.
