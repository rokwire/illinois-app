//
//  UIColor+InaParse.m
//  InaUtils
//
//  Created by Mihail Varbanov on 2/12/19.
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

#import "UIColor+InaParse.h"

#import "NSDictionary+InaTypedValue.h"

//////////////////////////////////
// UIColor+InaParse

@implementation UIColor(InaParse)

+ (UIColor*)inaColorWithHex:(NSString*)hexString {
	return [self inaColorWithHex:hexString defaults:nil];
}

+ (UIColor*)inaColorWithHex:(NSString*)hexString defaults:(UIColor*)defaultColor {

	NSUInteger scanPos = ((0 < hexString.length) && ([hexString characterAtIndex:0] == '#')) ? 1 : 0; // bypass '#' character
	NSUInteger scanLen = hexString.length - scanPos;
	if ((scanLen != 8) && (scanLen != 6))
		return defaultColor;

	NSScanner *scanner = [NSScanner scannerWithString:hexString];
	[scanner setScanLocation:scanPos];

	unsigned int argb = 0x00000000;
	if (![scanner scanHexInt:&argb])
		return defaultColor;

	float alpha = (scanLen == 8) ?
				  ((argb & 0xFF000000) >> 24) / 255.0f : 1.0f;
	float red   = ((argb & 0x00FF0000) >> 16) / 255.0f;
	float green = ((argb & 0x0000FF00) >>  8) / 255.0f;
	float blue  = ((argb & 0x000000FF))       / 255.0f;
	return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (NSString*)inaHexString {
	CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
	[self getRed:&red green:&green blue:&blue alpha:&alpha];
	
	return (alpha == 1.0) ?
		[NSString stringWithFormat:@"#%02x%02x%02x", (int)(red*255), (int)(green*255), (int)(blue*255)] :
		[NSString stringWithFormat:@"#%02x%02x%02x%02x", (int)(alpha*255), (int)(red*255), (int)(green*255), (int)(blue*255)];
}

@end

//////////////////////////////////
// NSDictionary+InaTypedColor

@implementation NSDictionary(InaTypedColor)

- (UIColor*)inaColorForKey:(id)key {
	return [self inaColorForKey:(id)key defaults:nil];
}

- (UIColor*)inaColorForKey:(id)key defaults:(UIColor*)defaultValue {
	return [UIColor inaColorWithHex:[self inaStringForKey:key]] ?: defaultValue;
}

@end

