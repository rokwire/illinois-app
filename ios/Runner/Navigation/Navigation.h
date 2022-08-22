//
//  Navigation.h
//  Runner
//
//  Created by Mihail Varbanov on 8/19/22.
//  Copyright 2022 Board of Trustees of the University of Illinois.
//

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
#import <CoreLocation/CLLocation.h>

@class NavRoute, NavRouteLeg, NavRouteStep, NavCoord, NavBounds, NavIntVal;

//////////////////////////////////////////////
// Navigation

@interface Navigation : NSObject
+ (void)findRouteFromOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination travelMode:(NSString*)travelMode completionHandler:(void(^)(NavRoute* route, NSError* error))completionHandler;
+ (void)findRoutesFromOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination travelMode:(NSString*)travelMode completionHandler:(void(^)(NSArray<NavRoute*>* route, NSError* error))completionHandler;
@end

//////////////////////////////////////////////
// NavRoute

@interface NavRoute : NSObject

@property (nonatomic, strong) NSString* summary;
@property (nonatomic, strong) NSString* copyrights;
@property (nonatomic, strong) NavBounds* bounds;
@property (nonatomic, strong) NSArray<NavCoord*>* overviewPoints;
@property (nonatomic, strong) NSArray<NavRouteLeg*>* legs;

@property (nonatomic, readonly)  NSString* startAddress;
@property (nonatomic, readonly)  NSString* endAddress;
@property (nonatomic, readonly)  NavCoord* startLocation;
@property (nonatomic, readonly)  NavCoord* endLocation;
@property (nonatomic, readonly)  NSString* description;
@property (nonatomic, readonly)  NSString* logString;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;

+ (NSArray<NavRoute*>*)createListFromJsonList:(NSArray*)jsonList;
+ (NSString*)loadUrlFromOrigin:(NavCoord*)origin toDestination:(NavCoord*)destination;
+ (NSString*)loadUrlFromOrigin:(NavCoord*)origin toDestination:(NavCoord*)destination throughWaypoints:(NSArray*)waypoints withAlternatives:(bool)alternatives;

@end

//////////////////////////////////////////////
// NavRouteLeg

@interface NavRouteLeg : NSObject

@property (nonatomic, strong) NSString* startAddress;
@property (nonatomic, strong) NSString* endAddress;
@property (nonatomic, strong) NavCoord* startLocation;
@property (nonatomic, strong) NavCoord* endLocation;
@property (nonatomic, strong) NavIntVal* duration;
@property (nonatomic, strong) NavIntVal* distance;
@property (nonatomic, strong) NSArray<NavRouteStep*>* steps;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
+ (NSArray<NavRouteLeg*>*)createListFromJsonList:(NSArray*)jsonList;
@end

//////////////////////////////////////////////
// NavRouteStep

@interface NavRouteStep : NSObject

@property (nonatomic, strong) NSString* travelMode;
@property (nonatomic, strong) NSString* instructionHtml;
@property (nonatomic, strong) NavCoord* startLocation;
@property (nonatomic, strong) NavCoord* endLocation;
@property (nonatomic, strong) NavIntVal* duration;
@property (nonatomic, strong) NavIntVal* distance;
@property (nonatomic, strong) NSArray<NavCoord*>* points;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
+ (NSArray<NavRouteStep*>*)createListFromJsonList:(NSArray*)jsonList;
@end

//////////////////////////////////////////////
// NavTravelMode

extern NSString * const kNavTravelModeWalking;
extern NSString * const kNavTravelModeBicycling;
extern NSString * const kNavTravelModeDriving;
extern NSString * const kNavTravelModeTransit;

//////////////////////////////////////////////
// NavCoord

@interface NavCoord : NSObject

@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude;
- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
- (instancetype)initWithLocation:(CLLocation*)location;
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

+ (instancetype)createWithLatitude:(double)latitude longitude:(double)longitude;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
+ (instancetype)createWithLocation:(CLLocation*)location;
+ (instancetype)createWithCoordinate:(CLLocationCoordinate2D)coordinate;

+ (NSMutableArray*)createListFromEncodedString:(NSString*)encodedString;

- (bool)isEqualToCoord:(NavCoord*)navCoord;

@end

//////////////////////////////////////////////
// NavBounds

@interface NavBounds : NSObject

@property (nonatomic, strong) NavCoord *northeast;
@property (nonatomic, strong) NavCoord *southwest;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavIntVal

@interface NavIntVal : NSObject

@property (nonatomic, assign) int		value;
@property (nonatomic, strong) NSString	*text;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

