//
//  TableCell.h
//  ZLThemeKit_Example
//
//  Created by admin on 2025/11/25.
//  Copyright © 2025 fanpeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TableCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

NS_ASSUME_NONNULL_END
