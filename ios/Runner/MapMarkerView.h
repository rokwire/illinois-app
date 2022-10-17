//
//  MapMarkerView.h
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

#import <UIKit/UIKit.h>

/////////////////////////////////
// MapMarkerDisplayMode

typedef NS_ENUM(NSInteger, MapMarkerDisplayMode) {
	MapMarkerDisplayMode_Plain,
	MapMarkerDisplayMode_Title,
	MapMarkerDisplayMode_Extended,
};

/////////////////////////////////
// MapMarkerView

@interface MapMarkerView : UIView
+ (instancetype)createFromExplore:(NSDictionary*)explore;
+ (instancetype)createFromExplore:(NSDictionary*)explore displayMode:(MapMarkerDisplayMode)displayMode;

@property (nonatomic) MapMarkerDisplayMode displayMode;
@property (nonatomic) bool blurred;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *descr;
@property (nonatomic, readonly) CGPoint anchor;

+ (UIImage*)markerImageWithHexColor:(NSString*)hexColor;
@end

@interface MapMarkerView2 : UIView
- (id)initWithIcon:(UIImage*)icon iconAnchor:(CGPoint)iconAnchor title:(NSString*)title descr:(NSString*)descr displayMode:(MapMarkerDisplayMode)displayMode;

@property (nonatomic) MapMarkerDisplayMode displayMode;
@property (nonatomic, readonly) CGPoint iconAnchor;
@property (nonatomic, readonly) CGPoint anchor;

+ (UIImage*)markerImageWithHexColor:(NSString*)hexColor;
+ (UIImage*)groupMarkerImageWithHexColor:(NSString*)hexColor count:(NSInteger)count;
@end

