//
//  MapMarkerView.m
//  Runner
//
//  Created by Mihail Varbanov on 7/15/19.
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

#import "MapMarkerView.h"

#import "NSDictionary+InaTypedValue.h"
#import "UIColor+InaParse.h"
#import "NSDictionary+UIUCExplore.h"
#import "CGGeometry+InaUtils.h"
#import "InaSymbols.h"
#import "UILabel+InaMeasure.h"

#import <GoogleMaps/GoogleMaps.h>

@interface MapExploreMarkerView : MapMarkerView
- (instancetype)initWithExplore:(NSDictionary*)explore displayMode:(MapMarkerDisplayMode)displayMode;
@end

@interface MapExploresMarkerView : MapMarkerView
- (instancetype)initWithExplore:(NSDictionary*)explore displayMode:(MapMarkerDisplayMode)displayMode;
@end

/////////////////////////////////
// MapMarkerView

@interface MapMarkerView() {}
@property (nonatomic) NSDictionary *explore;
@end

@implementation MapMarkerView

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
	}
	return self;
}

+ (instancetype)createFromExplore:(NSDictionary*)explore {
	return [self createFromExplore:explore displayMode: MapMarkerDisplayMode_Plain];
}

+ (instancetype)createFromExplore:(NSDictionary*)explore displayMode:(MapMarkerDisplayMode)displayMode {
	return (1 < explore.uiucExplores.count) ?
		[[MapExploresMarkerView alloc] initWithExplore:explore displayMode:displayMode] :
		[[MapExploreMarkerView alloc] initWithExplore:explore displayMode:displayMode];
}

- (void)setDisplayMode:(MapMarkerDisplayMode)displayMode {
	if (_displayMode != displayMode) {
		_displayMode = displayMode;
		[self updateDisplayMode];
	}
}

- (void)updateDisplayMode {
}

- (void)setBlurred:(bool)blurred {
	if (_blurred != blurred) {
		_blurred = blurred;
		[self updateBlurred];
	}
}

- (void)updateBlurred {
}

+ (UIImage*)markerImageWithHexColor:(NSString*)hexColor {

	static NSMutableDictionary *gMarkerImageMap = nil;
	if (gMarkerImageMap == nil) {
		gMarkerImageMap = [[NSMutableDictionary alloc] init];
	}
	
	UIImage *image = [gMarkerImageMap objectForKey:hexColor];
	if (image == nil) {
		UIColor *color = [UIColor inaColorWithHex:hexColor];
		image = [GMSMarker markerImageWithColor:color];
		if (image != nil) {
			[gMarkerImageMap setObject:image forKey:hexColor];
		}
	}
	return image;
}

@end


/////////////////////////////////
// MapExploreMarkerView

CGFloat const kExploreMarkerIconSize0 = 20;
CGFloat const kExploreMarkerIconSize1 = 30;
CGFloat const kExploreMarkerIconSize2 = 40;
CGFloat const kExploreMarkerIconSize[3] = { kExploreMarkerIconSize0, kExploreMarkerIconSize1, kExploreMarkerIconSize2 };

CGFloat const kExploreMarkerIconGutter = 3;
CGFloat const kExploreMarkerTitleFontSize = 12;
CGFloat const kExploreMarkerDescrFontSize = 12;
CGSize  const kExploreMarkerViewSize = { 180, kExploreMarkerIconSize2 + kExploreMarkerIconGutter + kExploreMarkerTitleFontSize + kExploreMarkerDescrFontSize };

@interface MapExploreMarkerView() {
	UIImageView *iconView;
	UILabel     *titleLabel;
	UILabel     *descrLabel;
}
@end

@implementation MapExploreMarkerView

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
	
		//self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
	
		//UIImage *markerImage = [UIImage imageNamed:@"maps-icon-marker-circle-40"];
		iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[self addSubview:iconView];

		titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		titleLabel.font = [UIFont boldSystemFontOfSize:kExploreMarkerTitleFontSize];
		titleLabel.textAlignment = NSTextAlignmentCenter;
		titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
		titleLabel.textColor = [UIColor inaColorWithHex:@"13294b"]; // darkSlateBlueTwo
		titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		titleLabel.shadowOffset = CGSizeMake(1, 1);
		[self addSubview:titleLabel];

		descrLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		descrLabel.font = [UIFont boldSystemFontOfSize:kExploreMarkerDescrFontSize];
		descrLabel.textAlignment = NSTextAlignmentCenter;
		descrLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
		descrLabel.textColor = [UIColor inaColorWithHex:@"244372"]; // darkSlateBlue
		descrLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		descrLabel.shadowOffset = CGSizeMake(1, 1);
		[self addSubview:descrLabel];

		[self updateDisplayMode];
	}
	return self;
}

- (instancetype)initWithExplore:(NSDictionary*)explore displayMode:(MapMarkerDisplayMode)displayMode {
	if (self = [self initWithFrame:CGRectMake(0, 0, kExploreMarkerViewSize.width, kExploreMarkerViewSize.height)]) {
		self.explore = explore;
		self.displayMode = displayMode;
		iconView.image = [self.class markerImageWithHexColor:explore.uiucExploreMarkerHexColor];
		titleLabel.text = explore.uiucExploreTitle;
		descrLabel.text = explore.uiucExploreDescription;
	}
	return self;
}

- (void)layoutSubviews {
	CGSize contentSize = self.frame.size;

	CGFloat y = 0;
	NSInteger maxIconIndex = _countof(kExploreMarkerIconSize) - 1;
	
	CGSize iconSize = iconView.image.size;

	CGFloat iconH = kExploreMarkerIconSize[MIN(MAX(self.displayMode, 0), maxIconIndex)];
	CGFloat iconW = (0 < iconSize.height) ? (iconSize.width * iconH / iconSize.height) : 0;

	CGFloat iconMaxH = kExploreMarkerIconSize[maxIconIndex];

	iconView.frame = CGRectMake((contentSize.width - iconW) / 2, iconMaxH - iconH, iconW, iconH);
	y += iconMaxH + kExploreMarkerIconGutter;

	CGFloat titleH = titleLabel.font.pointSize;
	titleLabel.frame = CGRectMake(0, y, contentSize.width, titleH);
	y += titleH;

	CGFloat descrH = descrLabel.font.pointSize;
	descrLabel.frame = CGRectMake(0, y, contentSize.width, descrH);
	y += descrH;
}

- (void)updateDisplayMode {
	titleLabel.hidden = (self.displayMode < MapMarkerDisplayMode_Title);
	descrLabel.hidden = (self.displayMode < MapMarkerDisplayMode_Extended);
	[self setNeedsLayout];
}

- (void)updateBlurred {
	iconView.image = [self.class markerImageWithHexColor:self.blurred ? @"#a0a0a0" : self.explore.uiucExploreMarkerHexColor];
	titleLabel.textColor = self.blurred ? [UIColor grayColor] : [UIColor inaColorWithHex:@"13294b"]; // darkSlateBlueTwo
	descrLabel.textColor = self.blurred ? [UIColor grayColor] : [UIColor inaColorWithHex:@"244372"]; // darkSlateBlue
}

- (NSString*)title {
	return titleLabel.text;
}

- (NSString*)descr {
	return descrLabel.text;
}

- (CGPoint)anchor {
	return CGPointMake(0.5, kExploreMarkerIconSize[_countof(kExploreMarkerIconSize) - 1] / kExploreMarkerViewSize.height);
}

@end

/////////////////////////////////
// MapExploresMarkerView

CGFloat const kExploresMarkerIconSize0 = 16;
CGFloat const kExploresMarkerIconSize1 = 20;
CGFloat const kExploresMarkerIconSize2 = 24;
CGFloat const kExploresMarkerIconSize[3] = { kExploresMarkerIconSize0, kExploresMarkerIconSize1, kExploresMarkerIconSize2 };

CGFloat const kExploresMarkerCountFontSize0 = 10;
CGFloat const kExploresMarkerCountFontSize1 = 12.5;
CGFloat const kExploresMarkerCountFontSize2 = 15;
CGFloat const kExploresMarkerCountFontSize[3] = { kExploresMarkerCountFontSize0, kExploresMarkerCountFontSize1, kExploresMarkerCountFontSize2 };

CGFloat const kExploresMarkerIconGutter = 3;
CGFloat const kExploresMarkerTitleFontSize = 12;
CGFloat const kExploresMarkerDescrFontSize = 12;
CGSize  const kExploresMarkerViewSize = { 180, kExploresMarkerIconSize2 + kExploresMarkerIconGutter + kExploresMarkerTitleFontSize + kExploresMarkerDescrFontSize };

@interface MapExploresMarkerView() {
	UIView		*circleView;
	UILabel     *countLabel;
	UILabel     *titleLabel;
	UILabel     *descrLabel;
}
@end

@implementation MapExploresMarkerView

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
	
		//self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
		
		circleView = [[UIView alloc] initWithFrame:CGRectZero];
		[self addSubview:circleView];
		
		countLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		//countLabel.font = [UIFont boldSystemFontOfSize:kExploresMarkerCountFontSize0];
		countLabel.textAlignment = NSTextAlignmentCenter;
		countLabel.textColor = [UIColor whiteColor];
		[self addSubview:countLabel];

		titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		titleLabel.font = [UIFont boldSystemFontOfSize:kExploresMarkerTitleFontSize];
		titleLabel.textAlignment = NSTextAlignmentCenter;
		titleLabel.textColor = [UIColor inaColorWithHex:@"13294b"]; // darkSlateBlueTwo
		titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		titleLabel.shadowOffset = CGSizeMake(1, 1);
		[self addSubview:titleLabel];

		descrLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		descrLabel.font = [UIFont boldSystemFontOfSize:kExploresMarkerDescrFontSize];
		descrLabel.textAlignment = NSTextAlignmentCenter;
		descrLabel.textColor = [UIColor inaColorWithHex:@"244372"]; // darkSlateBlue
		descrLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		descrLabel.shadowOffset = CGSizeMake(1, 1);
		[self addSubview:descrLabel];

		[self updateDisplayMode];
	}
	return self;
}

- (instancetype)initWithExplore:(NSDictionary*)explore displayMode:(MapMarkerDisplayMode)displayMode {
	if (self = [self initWithFrame:CGRectMake(0, 0, kExploresMarkerViewSize.width, kExploresMarkerViewSize.height)]) {
		self.explore = explore;
		self.displayMode = displayMode;

		circleView.backgroundColor = [UIColor inaColorWithHex:explore.uiucExploreMarkerHexColor];
		circleView.layer.borderColor = [[UIColor blackColor] CGColor];
		circleView.layer.borderWidth = 0.5;

		countLabel.text = [NSString stringWithFormat:@"%d", (int)explore.uiucExplores.count];
		titleLabel.text = explore.uiucExploreTitle;
		descrLabel.text = explore.uiucExploreDescription;
	}
	return self;
}

- (void)layoutSubviews {
	CGSize contentSize = self.frame.size;

	CGFloat y = 0;
	NSInteger maxIconIndex = _countof(kExploresMarkerIconSize) - 1;
	CGFloat iconSize = kExploresMarkerIconSize[MIN(MAX(self.displayMode, 0), maxIconIndex)];
	CGFloat iconMaxSize = kExploresMarkerIconSize[maxIconIndex];
	CGFloat iconY = (iconMaxSize - iconSize) / 2;
	CGFloat iconX = (contentSize.width - iconSize) / 2;

	circleView.frame = CGRectMake(iconX, iconY, iconSize, iconSize);
	if (circleView.layer.cornerRadius != iconSize/2) {
		circleView.layer.cornerRadius = iconSize/2;
	}

	CGFloat countH = countLabel.font.pointSize;
	countLabel.frame = CGRectMake(iconX, iconY + (iconSize - countH) / 2 , iconSize, countH);

	y += iconMaxSize + kExploresMarkerIconGutter;

	CGFloat titleH = titleLabel.font.pointSize;
	titleLabel.frame = CGRectMake(0, y, contentSize.width, titleH);
	y += titleH;

	CGFloat descrH = descrLabel.font.pointSize;
	descrLabel.frame = CGRectMake(0, y, contentSize.width, descrH);
	y += descrH;
}

- (void)updateDisplayMode {
	countLabel.font = [UIFont boldSystemFontOfSize:kExploresMarkerCountFontSize[MIN(MAX(self.displayMode, 0), _countof(kExploresMarkerCountFontSize) - 1)]];
	titleLabel.hidden = (self.displayMode < MapMarkerDisplayMode_Title);
	descrLabel.hidden = (self.displayMode < MapMarkerDisplayMode_Extended);
	[self setNeedsLayout];
}

- (void)updateBlurred {
	circleView.backgroundColor = [UIColor inaColorWithHex:self.blurred ? @"#a0a0a0" : self.explore.uiucExploreMarkerHexColor];
	titleLabel.textColor = self.blurred ? [UIColor grayColor] : [UIColor inaColorWithHex:@"13294b"]; // darkSlateBlueTwo
	descrLabel.textColor = self.blurred ? [UIColor grayColor] : [UIColor inaColorWithHex:@"244372"]; // darkSlateBlue
}

- (NSString*)title {
	return titleLabel.text;
}

- (NSString*)descr {
	return descrLabel.text;
}

- (CGPoint)anchor {
	return CGPointMake(0.5, kExploresMarkerIconSize[_countof(kExploresMarkerIconSize) - 1] / 2 / kExploreMarkerViewSize.height);
}


@end

/////////////////////////////////
// MapMarkerView2

@interface MapMarkerView2() {
	UIImageView *iconView;
	UIView		  *popupView;
	UILabel     *titleLabel;
	UILabel     *descrLabel;
}

@property (nonatomic, readwrite) CGPoint iconAnchor;
@property (nonatomic, readonly) CGFloat contentHeight;
@end

@implementation MapMarkerView2

CGFloat const kMarkerIconSize = 20;
CGFloat const kGroupMarkerIconSize = 24;
CGFloat const kMarkerView2IconGutter = 3;
CGSize const  kMarkerView2PopupEdgeInsets = {4, 2};
CGFloat const kMarkerView2PopupInnerGutter = 2;
CGFloat const kMarkerView2TitleFontSize = 12;
NSInteger const kMarkerView2TitleLinesCount = 2;
CGFloat const kMarkerView2DescrFontSize = 10;
NSInteger const kMarkerView2DescrLinesCount = 1;
CGFloat const kMarkerView2Width = 150;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
	
		// self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
	
		iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[self addSubview:iconView];
		
		popupView = [[UIView alloc] initWithFrame:CGRectZero];
		popupView.backgroundColor = [UIColor whiteColor];
		popupView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
		popupView.layer.borderWidth = 0.5;
		popupView.layer.cornerRadius = 5;
		popupView.clipsToBounds = YES;
		[self addSubview:popupView];

		titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		titleLabel.font = self.class.titleFont;
		titleLabel.textAlignment = NSTextAlignmentCenter;
		titleLabel.lineBreakMode = (1 < kMarkerView2TitleLinesCount) ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
		titleLabel.numberOfLines = kMarkerView2TitleLinesCount;
		titleLabel.textColor = [UIColor inaColorWithHex:@"13294b"]; // darkSlateBlueTwo
		titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		titleLabel.shadowOffset = CGSizeMake(1, 1);
		[popupView addSubview:titleLabel];

		descrLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		descrLabel.font = self.class.descrFont;
		descrLabel.textAlignment = NSTextAlignmentCenter;
		descrLabel.lineBreakMode = (1 < kMarkerView2DescrLinesCount) ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
		descrLabel.numberOfLines = kMarkerView2DescrLinesCount;
		descrLabel.textColor = [UIColor inaColorWithHex:@"244372"]; // darkSlateBlue
		descrLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		descrLabel.shadowOffset = CGSizeMake(1, 1);
		[popupView addSubview:descrLabel];
	}
	return self;
}

- (id)initWithIcon:(UIImage*)icon iconAnchor:(CGPoint)iconAnchor title:(NSString*)title descr:(NSString*)descr displayMode:(MapMarkerDisplayMode)displayMode {
	CGFloat contentHeight = [self.class contentHeightForIcon:icon];
	if (self = [self initWithFrame:CGRectMake(0, 0, kMarkerView2Width, contentHeight)]) {
		iconView.image = icon;
		titleLabel.text = title;
		descrLabel.text = descr;
		_displayMode = displayMode;
		_iconAnchor = iconAnchor;
		[self updateDisplayMode];
	}
	return self;
}

- (void)layoutSubviews {
	CGSize contentSize = self.frame.size;
	CGFloat contentH = contentSize.height;
	CGFloat contentW = contentSize.width;
	
	CGSize iconSize = iconView.image.size;
	iconView.frame = CGRectMake((contentW - iconSize.width) / 2, contentH - iconSize.height, iconSize.width, iconSize.height);
	contentH = MAX(contentH - iconSize.height - kMarkerView2IconGutter, 0);
	
	
	CGFloat popupX = kMarkerView2PopupEdgeInsets.width;
	CGFloat popupW = MAX(contentW - 2 * kMarkerView2PopupEdgeInsets.width, 0);

	CGFloat popupH = 0, titleH = 0, descrH = 0;
	if (MapMarkerDisplayMode_Title <= self.displayMode) {
		titleH = [titleLabel inaTextSizeForBoundWidth: popupW].height;
		popupH += titleH + 2 * kMarkerView2PopupEdgeInsets.height;
	}
	if (MapMarkerDisplayMode_Extended <= self.displayMode) {
		descrH = [descrLabel inaTextSizeForBoundWidth: popupW].height;
		popupH += descrH + kMarkerView2PopupInnerGutter;
	}
	
	CGFloat popupY = MAX(contentH - popupH, 0);
	popupView.frame = CGRectMake(0, popupY, contentW, popupH);
	
	popupY = kMarkerView2PopupEdgeInsets.height;
	popupH = MAX(popupH - 2 * kMarkerView2PopupEdgeInsets.height, 0);
	
	titleLabel.frame = CGRectMake(popupX, popupY, popupW, titleH);
	popupY += titleH + kMarkerView2PopupInnerGutter;
	descrLabel.frame = CGRectMake(popupX, popupY, popupW, descrH);
}

- (void)setDisplayMode:(MapMarkerDisplayMode)displayMode {
	if (_displayMode != displayMode) {
		_displayMode = displayMode;
		[self updateDisplayMode];
	}
}

- (void)updateDisplayMode {
	popupView.hidden = (self.displayMode < MapMarkerDisplayMode_Title);
	titleLabel.hidden = (self.displayMode < MapMarkerDisplayMode_Title);
	descrLabel.hidden = (self.displayMode < MapMarkerDisplayMode_Extended);
	[self setNeedsLayout];
}

- (CGFloat)iconHeight {
	return iconView.image.size.height;
}

- (CGFloat)contentHeight {
	return [self.class contentHeightForIcon:iconView.image titleFont:titleLabel.font descrFont:descrLabel.font];
}

+ (UIFont*)titleFont {
	return [UIFont boldSystemFontOfSize:kExploreMarkerTitleFontSize];
}

+ (UIFont*)descrFont {
	return [UIFont systemFontOfSize:kExploreMarkerDescrFontSize];
}

+ (CGFloat)contentHeightForIcon:(UIImage*)icon {
	return [self contentHeightForIcon:icon titleFont:self.titleFont descrFont:self.descrFont];
}

+ (CGFloat)contentHeightForIcon:(UIImage*)icon titleFont:(UIFont*)titleFont descrFont:(UIFont*)descrFont {
	return icon.size.height + kMarkerView2IconGutter +
		2 * kMarkerView2PopupEdgeInsets.height +
		titleFont.lineHeight * kMarkerView2TitleLinesCount +
		kMarkerView2PopupInnerGutter +
		descrFont.lineHeight * kMarkerView2DescrLinesCount;
}

- (CGPoint)anchor {
	CGFloat contentH = self.contentHeight;
	return CGPointMake(_iconAnchor.x, (contentH - (1 - _iconAnchor.y) * self.iconHeight) / contentH);
}

+ (UIImage*)markerImageWithHexColor:(NSString*)hexColor {

	static NSMutableDictionary *gMarkerImageMap = nil;
	if (gMarkerImageMap == nil) {
		gMarkerImageMap = [[NSMutableDictionary alloc] init];
	}
	
	UIImage *image = [gMarkerImageMap objectForKey:hexColor];
	if (image == nil) {
		UIImage *imageSource = [MapMarkerView markerImageWithHexColor:hexColor];
		if (imageSource != nil) {
			CGSize imageSize = CGSizeMake(kMarkerIconSize, kMarkerIconSize * imageSource.size.height / imageSource.size.width);
			UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
			[imageSource drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
			image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			if (image != nil) {
				[gMarkerImageMap setObject:image forKey:hexColor];
			}
		}
	}
	return image;
}

+ (UIImage*)groupMarkerImageWithHexColor:(NSString*)hexColor count:(NSInteger)count {

	static NSMutableDictionary *gGroupMarkerImageMap = nil;
	if (gGroupMarkerImageMap == nil) {
		gGroupMarkerImageMap = [[NSMutableDictionary alloc] init];
	}
	
	NSString *imageKey = [NSString stringWithFormat:@"%@%@", @(count), hexColor];
	UIImage *image = [gGroupMarkerImageMap objectForKey:imageKey];
	if (image == nil) {
		UIColor *color = [UIColor inaColorWithHex:hexColor];
		image = [self createGroupMarkerImageWithColor:color count:count];
		if (image != nil) {
			[gGroupMarkerImageMap setObject:image forKey:imageKey];
		}
	}
	return image;
}

+ (UIImage*)createGroupMarkerImageWithColor:(UIColor*)color count:(NSInteger)count {
	UIImage* result = nil;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace != NULL) {
		CGFloat markerSize = kGroupMarkerIconSize;
		CGContextRef context = CGBitmapContextCreate(nil, markerSize, markerSize, 8, kExploresMarkerIconSize2 * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
		if (context != NULL) {
			CGRect markerRect = CGRectMake(1, 1, markerSize - 2, markerSize - 2);
			
			CGContextSetFillColorWithColor(context, color.CGColor);
			CGContextFillEllipseInRect(context, markerRect);
			
			CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
			CGContextSetLineWidth(context, 0.5);
			CGContextStrokeEllipseInRect(context, markerRect);
			
			NSString *text = [[NSNumber numberWithInteger:count] stringValue];
			UIGraphicsPushContext(context);

			CGContextSaveGState(context);
			CGContextTranslateCTM(context, 0.0f, markerSize);
			CGContextScaleCTM(context, 1.0f, -1.0f);

			NSStringDrawingOptions options = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
			
			CGSize textSize;
			CGFloat fontSize = 15;
			while (8 < fontSize) {
				NSDictionary *attributes = @{
					NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
				};
				CGSize rawTextSize = [text sizeWithAttributes:attributes];
				textSize = CGSizeMake(ceil(rawTextSize.width), ceil(rawTextSize.height));
				if (textSize.width <= markerRect.size.width) {
					break;
				}
				else {
					fontSize--;
				}
			}
			
			NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
			paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
			paragraphStyle.alignment = NSTextAlignmentCenter;
			
			NSDictionary *attributes = @{
				NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize],
				NSForegroundColorAttributeName: UIColor.whiteColor,
				NSParagraphStyleAttributeName: paragraphStyle,
			};
			
			CGRect textRect = CGRectMake(
				markerRect.origin.x + (markerRect.size.width - textSize.width) / 2,
				markerRect.origin.y + (markerRect.size.height - textSize.height) / 2,
				textSize.width, textSize.height);
			[text drawWithRect:textRect options:options attributes:attributes context: NULL];

			CGContextRestoreGState(context);
			UIGraphicsPopContext();

			CGImageRef resultImageRef = CGBitmapContextCreateImage(context);;
			if (resultImageRef != nil) {
				result = [[UIImage alloc] initWithCGImage:resultImageRef];
			}
			CGContextRelease(context);
		}
		CGColorSpaceRelease( colorSpace );
	}
	return result;
}

@end
