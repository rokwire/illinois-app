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

@class NavRoute, NavRouteLeg, NavRouteStep,
	NavTransitDetails, NavTransitStop, NavTransitLine, NavTransitVehicle, NavTransitAgency,
	NavCoord, NavBounds, NavPolyline, NavIntVal, NavTimeVal;

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
@property (nonatomic, strong) NavPolyline* overviewPolyline;
@property (nonatomic, strong) NSArray<NavRouteLeg*>* legs;

@property (nonatomic, readonly) NSString* startAddress;
@property (nonatomic, readonly) NSString* endAddress;
@property (nonatomic, readonly) NavCoord* startLocation;
@property (nonatomic, readonly) NavCoord* endLocation;
@property (nonatomic, readonly) NSNumber* distance;
@property (nonatomic, readonly) NSNumber* duration;
@property (nonatomic, readonly) NSString* logString;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;

+ (NSArray<NavRoute*>*)createListFromJsonList:(NSArray*)jsonList;
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
@property (nonatomic, strong) NSString* instructionsHtml;
@property (nonatomic, strong) NavCoord* startLocation;
@property (nonatomic, strong) NavCoord* endLocation;
@property (nonatomic, strong) NavIntVal* duration;
@property (nonatomic, strong) NavIntVal* distance;
@property (nonatomic, strong) NavPolyline* polyline;
@property (nonatomic, strong) NSString* maneuver;
@property (nonatomic, strong) NSArray<NavRouteStep*>* steps;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
+ (NSArray<NavRouteStep*>*)createListFromJsonList:(NSArray*)jsonList;
@end

//////////////////////////////////////////////
// NavTransitDetails

@interface NavTransitDetails : NSObject
@property (nonatomic, strong) NavTransitStop* arrivalStop;
@property (nonatomic, strong) NavTimeVal* arrivalTime;
@property (nonatomic, strong) NavTransitStop* departureStop;
@property (nonatomic, strong) NavTimeVal* departureTime;
@property (nonatomic, strong) NavTransitLine* line;
@property (nonatomic, strong) NSString* headsign;
@property (nonatomic, assign) NSInteger numStops;


- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavTransitStop

@interface NavTransitStop : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NavCoord* location;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavTransitLine

@interface NavTransitLine : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* shortName;
@property (nonatomic, strong) NSString* color;
@property (nonatomic, strong) NSString* textColor;
@property (nonatomic, strong) NavTransitVehicle* vehicle;
@property (nonatomic, strong) NSArray<NavTransitAgency*>* agencies;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavTransitVehicle

@interface NavTransitVehicle : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* icon;
@property (nonatomic, strong) NSString* type;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavTransitAgency

@interface NavTransitAgency : NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* phone;
@property (nonatomic, strong) NSString* url;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
+ (NSArray<NavTransitAgency*>*)createListFromJsonList:(NSArray*)jsonList;
@end

//////////////////////////////////////////////
// NavTravelMode

extern NSString * kNavTravelModeWalking;
extern NSString * kNavTravelModeBicycling;
extern NSString * kNavTravelModeDriving;
extern NSString * kNavTravelModeTransit;

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
// NavPolyline

@interface NavPolyline : NSObject

@property (nonatomic, strong) NSString *points;
@property (nonatomic, readonly) NSArray<NavCoord*>* coordinates;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavIntVal

@interface NavIntVal : NSObject

@property (nonatomic, assign) NSInteger value;
@property (nonatomic, strong) NSString	*text;

- (instancetype)initWithJsonData:(NSDictionary*)jsonData;
+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end

//////////////////////////////////////////////
// NavTimeVal

@interface NavTimeVal : NavIntVal

@property (nonatomic, strong) NSString	*timeZone;

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData;
@end
