//
//  PurrCollectionViewCell.h
//  Purrpad
//
//  Created by Reza on 5/7/18.
//  Copyright © 2018 EccentricSolo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PurrCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UITextView *purrTextView;
@property (weak, nonatomic) IBOutlet UILabel *purrLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cellBGImageView;

@end
