//
//  ZLViewController.m
//  ZLThemeKit
//
//  Created by fanpeng on 11/25/2025.
//  Copyright (c) 2025 fanpeng. All rights reserved.
//

#import "ZLViewController.h"
#import "TableCell.h"
#import <ZLThemeKit/ZLThemeKit.h>
@interface ZLViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UISegmentedControl *themeSegment;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ZLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    {
        //通过txt加载
        [ZLThemeManager.share loadFromColorFilePath:@"GMColorTable.txt" imageFilePath:@"GMImageTable.txt" alphaFilePath:@"GMAlphaTable.txt"];
    }
    
    {
        //通过json格式info.plist字典加载
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Configure" ofType:@"plist"];
        NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        [ZLThemeManager.share loadFromDictionaryInfo:plistData];
    }
    
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TableCell" bundle:nil] forCellReuseIdentifier:@"TableCell"];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = UIColor.orangeColor;// 设置背景色
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.blackColor}; // 标题颜色
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }else {
        self.navigationController.navigationBar.barTintColor = UIColor.orangeColor;
        self.navigationController.navigationBar.backgroundColor = UIColor.orangeColor;
    }
    [self setupThemeSegment];

}
- (void)setupThemeSegment {
    self.themeSegment = [[UISegmentedControl alloc] initWithItems:@[@"NORMAL", @"NIGHT", @"RED"]];
    self.themeSegment.selectedSegmentIndex = 0;
    [self.themeSegment addTarget:self action:@selector(themeChanged:) forControlEvents:UIControlEventValueChanged];
    if ([ZLThemeManager.share.currentTheme isEqualToString:@"NORMAL"]) {
        self.themeSegment.selectedSegmentIndex = 0;
    }else if ([ZLThemeManager.share.currentTheme isEqualToString:@"NIGHT"]) {
        self.themeSegment.selectedSegmentIndex = 1;
    } else{
        self.themeSegment.selectedSegmentIndex = 2;
    }
    self.themeSegment.frame = CGRectMake(20, 0, self.view.bounds.size.width - 40, 40);
    [self.navigationController.navigationBar addSubview:self.themeSegment];
    [self.themeSegment themeKit:^(UIControl * _Nonnull view) {
        UISegmentedControl *seg = (UISegmentedControl *)view;
        if (@available(iOS 13.0, *)) {
            seg.selectedSegmentTintColor = kColorWithKey(@"TINT");
        } else {
            // Fallback on earlier versions
        }
    }];
}
- (void)themeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [ZLThemeManager.share updateTheme:@"NORMAL"];
    }else if (sender.selectedSegmentIndex == 1) {
        [ZLThemeManager.share updateTheme:@"NIGHT"];
    }else if (sender.selectedSegmentIndex == 2) {
        [ZLThemeManager.share updateTheme:@"RED"];
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableCell" forIndexPath:indexPath];
    cell.label.text = [NSString stringWithFormat:@"This is row %ld", (long)indexPath.row];
    cell.label.themeKit.textColor = kColorWithKey(@"TEXT");
    cell.contentView.themeKit.backgroundColor = kColorWithKey(@"BG");
    cell.imgView.themeKit.image = kImageWithKey(@"image2");
    cell.progress.themeKit.tintColor = kColorWithKey(@"TINT");
    [cell.button.themeKit setImage:kImageWithKey(@"image3") forState:UIControlStateNormal];
    [cell.button.themeKit setImage:kImageWithKey(@"image4") forState:UIControlStateSelected];
    return cell;
}

@end
