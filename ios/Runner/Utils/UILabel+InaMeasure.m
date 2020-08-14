//
//  UILabel+InaMeasure.m
//  NJII
//
//  Created by Mihail Varbanov on 2/14/19.
//  Copyright 2020 Board of Trustees of the University of Illinois.
    
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UILabel+InaMeasure.h"

@implementation UILabel(InaMeasure)

- (CGSize)inaTextSize {
	CGSize textSize = [self.text sizeWithAttributes:@{
		NSFontAttributeName:self.font
	}];
	return CGSizeMake(ceil(textSize.width), ceil(textSize.height));
}

- (CGSize)inaTextSizeForBoundWidth:(CGFloat)baundWidth {
	CGFloat boundHeight = (self.numberOfLines == 0) ? CGFLOAT_MAX : ((self.font.lineHeight * self.numberOfLines) + (self.font.leading * MAX(self.numberOfLines - 1, 0)) + 0.5);
	return [self inaTextSizeForBoundSize:CGSizeMake(baundWidth, boundHeight)];
}


- (CGSize)inaTextSizeForBoundSize:(CGSize)boundSize {

	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.lineBreakMode = self.lineBreakMode;

	NSDictionary *attributes = @{
		NSFontAttributeName:self.font,
		NSParagraphStyleAttributeName:paragraphStyle
	};

	NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;

	CGSize textSize = [self.text boundingRectWithSize:boundSize options:options attributes:attributes context:nil].size;

	// Apple:
	// This method returns fractional sizes (in the size component of the returned CGRect);
	// to use a returned size to size views, you must raise its value to the nearest higher integer using the ceil function.
	return CGSizeMake(ceil(textSize.width), ceil(textSize.height));
}

- (CGSize)inaAttributedTextSize {
	CGSize textSize = self.attributedText.size;
	return CGSizeMake(ceil(textSize.width), ceil(textSize.height));
}

- (CGSize)inaAttributedTextSizeForBoundWidth:(CGFloat)baundWidth {
	return [self inaAttributedTextSizeForBoundSize:CGSizeMake(baundWidth, CGFLOAT_MAX)];
}


- (CGSize)inaAttributedTextSizeForBoundSize:(CGSize)boundSize {
	NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
	CGSize textSize = [self.attributedText boundingRectWithSize:boundSize options:options context:nil].size;
	return CGSizeMake(ceil(textSize.width), ceil(textSize.height));
}

@end
