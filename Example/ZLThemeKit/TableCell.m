//
//  TableCell.m
//  ZLThemeKit_Example
//
//  Created by admin on 2025/11/25.
//  Copyright © 2025 fanpeng. All rights reserved.
//

#import "TableCell.h"

@implementation TableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.button.layer.masksToBounds = YES;
    [self.button setTitle:@"" forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)tap:(id)sender {
    self.button.selected = !self.button.isSelected;
}

@end
