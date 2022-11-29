//
//  NSDictionary+UIUCExplore.h
//  UIUCUtils
//
//  Created by Mihail Varbanov on 5/9/19.
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, UIUCExploreType) {
	UIUCExploreType_Unknown,
	UIUCExploreType_Event,
	UIUCExploreType_Dining,
	UIUCExploreType_Laundry,
	UIUCExploreType_Parking,
	UIUCExploreType_Building,
	UIUCExploreType_MTDStop,
	UIUCExploreType_StudentCourse,
	UIUCExploreType_Appointment,
	UIUCExploreType_Explores,
};

NSString* UIUCExploreTypeToString(UIUCExploreType exploreType);
UIUCExploreType UIUCExploreTypeFromString(NSString* value);

@interface NSDictionary(UIUCExplore)
@property (nonatomic, readonly) UIUCExploreType uiucExploreType;
@property (nonatomic, readonly) UIUCExploreType uiucExploreContentType;
@property (nonatomic, readonly) NSString* uiucExploreTitle;
@property (nonatomic, readonly) NSString* uiucExploreMarkerHexColor;
@property (nonatomic, readonly) NSString* uiucExploreDescription;
@property (nonatomic, readonly) NSArray* uiucExplores;
@property (nonatomic, readonly) NSString* uiucExploreAddress;
@property (nonatomic, readonly) NSDictionary* uiucExploreLocation;
@property (nonatomic, readonly) NSDictionary* uiucExploreDestinationLocation;
@property (nonatomic, readonly) CLLocationCoordinate2D uiucExploreLocationCoordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D uiucLocationCoordinate;
@property (nonatomic, readonly) NSArray* uiucExplorePolygon;
@property (nonatomic, readonly) int uiucExploreLocationFloor;
@property (nonatomic, readonly) bool uiucSupportsDisplayModes;

+ (NSDictionary*)uiucExploreFromGroup:(NSArray*)explores;

@end

