//
//  Navigation.m
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

#import "Navigation.h"
#import "AppDelegate.h"
#import "NSDictionary+InaTypedValue.h"
#import "NSDictionary+UIUCConfig.h"
#import "CLLocationCoordinate2D+InaUtils.h"
#import "Navigation+Utils.h"

//////////////////////////////////////////////
// Navigation

@implementation Navigation

+ (void)findRouteFromOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination travelMode:(NSString*)travelMode
		completionHandler:(void(^)(NavRoute* route, NSError* error))completionHandler {
	[self _findRoutesFromOrigin:origin destination:destination travelMode:travelMode alternatives:false completionHandler:^(NSArray<NavRoute*>*routes, NSError* error) {
		if (completionHandler != nil) {
			completionHandler(routes.firstObject, error);
		}
	}];
	
}

+ (void)findRoutesFromOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination travelMode:(NSString*)travelMode
		completionHandler:(void(^)(NSArray<NavRoute*>* route, NSError* error))completionHandler {
	[self _findRoutesFromOrigin:origin destination:destination travelMode:travelMode alternatives:true completionHandler:completionHandler];
}

+ (void)_findRoutesFromOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination travelMode:(NSString*)travelMode alternatives:(bool)alternatives
		completionHandler:(void(^)(NSArray<NavRoute*>* routes, NSError* error))completionHandler {
	NSString *apiUrl = [AppDelegate.sharedInstance.thirdPartyServices inaStringForKey:@"google_directions_url"];
	NSString *apiKey = [AppDelegate.sharedInstance.secretKeys uiucConfigStringForPathKey:@"google.maps.api_key"];
	if ((0 < apiUrl.length) && (0 < apiKey.length)) {
		NSString *requestUrl = [NSString stringWithFormat:@"%@?origin=%.6f,%.6f&destination=%.6f,%.6f&mode=%@&alternatives=%@&language=%@&key=%@",
			apiUrl,
			origin.latitude, origin.longitude,
			destination.latitude, destination.longitude,
			travelMode,
			alternatives ? @"true" : @"false",
			NSLocale.currentLocale.languageCode,
			apiKey
		];
		
		NSURLSession *session = [NSURLSession sharedSession];
		NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
		NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
			if (completionHandler != nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self _didFindRoutesFromOrigin:response data:data error:error completionHandler:completionHandler];
				});
			}
		}];
		
		[task resume];
	}
	else if (completionHandler != nil) {
		completionHandler(nil, [NSError errorWithDomain:@"edu.illinois.rokwire" code:1 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Map directions not available.", nil) }]);
	}
}

+ (void)_didFindRoutesFromOrigin:(NSURLResponse*)response data:(NSData*)data error:(NSError*)error
		completionHandler:(void(^)(NSArray<NavRoute*>* route, NSError* error))completionHandler {
	if (data != nil) {
		NSInteger responseCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse*)response).statusCode : -1;
		if (responseCode == 200) {
			NSError *jsonError = nil;
			id responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
			if ([responseJson isKindOfClass:[NSDictionary class]]) {
				NSString *status = [responseJson inaStringForKey:@"status"];
				if ([status compare:@"OK" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
					NSArray<NavRoute*> *routes = [NavRoute createListFromJsonList:[responseJson inaArrayForKey:@"routes"]];
					if (routes != nil) {
						completionHandler(routes, nil);
					}
					else {
						completionHandler(nil, [NSError errorWithDomain:@"edu.illinois.rokwire" code:3 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Invalid server response.", nil) }]);
					}
				}
				else {
					NSString *errorMessage = [responseJson inaStringForKey:@"error_message"];
					completionHandler(nil, [NSError errorWithDomain:@"edu.illinois.rokwire" code:2 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@: %@", status, errorMessage] }]);
				}
			}
			else {
				completionHandler(nil, jsonError ?: [NSError errorWithDomain:@"edu.illinois.rokwire" code:3 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Invalid server response.", nil) }]);
			}
		}
		else {
			NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			completionHandler(nil, error ?: [NSError errorWithDomain:@"edu.illinois.rokwire" code:2 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@ %@", @(responseCode), responseString] }]);
		}
	}
	else {
		completionHandler(nil, error);
	}
}

@end

//////////////////////////////////////////////
// NavRoute

@implementation NavRoute

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavRoute alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_summary		      = [jsonData inaStringForKey:@"summary"];
	_copyrights		    = [jsonData inaStringForKey:@"copyrights"];
	_bounds			      = [NavBounds createFromJsonData:[jsonData inaDictForKey:@"bounds"]];
	_overviewPolyline = [NavPolyline createFromJsonData:[jsonData inaDictForKey:@"overview_polyline"]];
	_legs			        = [NavRouteLeg createListFromJsonList:[jsonData inaArrayForKey:@"legs"]];
}

+ (NSArray<NavRoute*>*)createListFromJsonList:(NSArray*)jsonList {
	NSMutableArray<NavRoute*>* result = nil;
	if (jsonList != nil) {
		result = [[NSMutableArray<NavRoute*> alloc] init];
		for (NSDictionary *dict in jsonList) {
			if ([dict isKindOfClass:[NSDictionary class]]) {
				NavRoute* value = [NavRoute createFromJsonData:dict];
				if (value != nil) {
					[result addObject: value];
				}
			}
		}
	}
	return result;
}

- (NavCoord*)startLocation {
	return _legs.firstObject.startLocation;
}

- (NavCoord*)endLocation {
	return _legs.lastObject.endLocation;
}

- (NSString*)startAddress {
	return _legs.firstObject.startAddress;
}

- (NSString*)endAddress {
	return _legs.lastObject.endAddress;
}

- (NSNumber*)distance {
	if (_legs != nil) {
		NSInteger totalDistance = 0;
		for (NavRouteLeg* leg in _legs) {
			totalDistance += leg.distance.value;
		}
		return [NSNumber numberWithInteger:totalDistance];
	}
	return nil;
}

- (NSNumber*)duration {
	if (_legs != nil) {
		NSInteger totalDuration = 0;
		for (NavRouteLeg* leg in _legs) {
			totalDuration += leg.duration.value;
		}
		return [NSNumber numberWithInteger:totalDuration];
	}
	return nil;
}


- (NSString*)logString {
	NSMutableString *logString = [[NSMutableString alloc] init];
	for (NavRouteLeg *leg in _legs) {
		for (NavRouteStep *step in leg.steps) {

			[logString appendString:step.instructionsHtml];
			[logString appendString:@"\n"];

			NSInteger startLen = logString.length;
			for (NavCoord* point in step.polyline.coordinates) {
				if (startLen < logString.length)
					[logString appendString:@", "];
				[logString appendFormat:@"{%.6f, %.6f}", point.latitude, point.longitude];
			}

			[logString appendString:@"\n\n"];
		}
	}
	return logString;
}

@end

//////////////////////////////////////////////
// NavRouteLeg

@implementation NavRouteLeg

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavRouteLeg alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_startAddress   = [jsonData inaStringForKey:@"start_address"];
	_endAddress     = [jsonData inaStringForKey:@"end_address"];
	_startLocation  = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"start_location"]];
	_endLocation    = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"end_location"]];
	_duration       = [NavIntVal createFromJsonData:[jsonData inaDictForKey:@"duration"]];
	_distance       = [NavIntVal createFromJsonData:[jsonData inaDictForKey:@"distance"]];
	_steps          = [NavRouteStep createListFromJsonList:[jsonData inaArrayForKey:@"steps"]];
}

+ (NSArray<NavRouteLeg*>*)createListFromJsonList:(NSArray*)jsonList {
	NSMutableArray<NavRouteLeg*>* result = nil;
	if (jsonList != nil) {
		result = [[NSMutableArray<NavRouteLeg*> alloc] init];
		for (NSDictionary *dict in jsonList) {
			if ([dict isKindOfClass:[NSDictionary class]]) {
				NavRouteLeg* value = [NavRouteLeg createFromJsonData:dict];
				if (value != nil) {
					[result addObject:value];
				}
			}
		}
	}
	return result;
}

@end

//////////////////////////////////////////////
// NavRouteStep

@implementation NavRouteStep

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavRouteStep alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_travelMode       = [jsonData inaStringForKey:@"travel_mode"];
	_instructionsHtml = [jsonData inaStringForKey:@"html_instructions"];
	_startLocation    = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"start_location"]];
	_endLocation      = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"end_location"]];
	_duration         = [NavIntVal createFromJsonData:[jsonData inaDictForKey:@"duration"]];
	_distance         = [NavIntVal createFromJsonData:[jsonData inaDictForKey:@"distance"]];
	_polyline         = [NavPolyline createFromJsonData:[jsonData inaDictForKey:@"polyline"]];
	_maneuver         = [jsonData inaStringForKey:@"maneuver"];
	_steps            = [NavRouteStep createListFromJsonList:[jsonData inaArrayForKey:@"steps"]];
}

+ (NSArray<NavRouteStep*>*)createListFromJsonList:(NSArray*)jsonList {
	NSMutableArray<NavRouteStep*>* result = nil;
	if (jsonList != nil) {
		result = [[NSMutableArray<NavRouteStep*> alloc] init];
		for (NSDictionary *dict in jsonList) {
			if ([dict isKindOfClass:[NSDictionary class]]) {
				NavRouteStep* value = [NavRouteStep createFromJsonData:dict];
				if (value != nil) {
					[result addObject:value];
				}
			}
		}
	}
	return result;
}

@end

//////////////////////////////////////////////
// NavTransitDetails

@implementation NavTransitDetails

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavTransitDetails alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_arrivalStop    = [NavTransitStop createFromJsonData:[jsonData inaDictForKey:@"arrival_stop"]];
	_arrivalTime    = [NavTimeVal createFromJsonData:[jsonData inaDictForKey:@"arrival_time"]];
	_departureStop  = [NavTransitStop createFromJsonData:[jsonData inaDictForKey:@"departure_stop"]];
	_departureTime  = [NavTimeVal createFromJsonData:[jsonData inaDictForKey:@"departure_time"]];
	_line           = [NavTransitLine createFromJsonData:[jsonData inaDictForKey:@"line"]];
	_headsign       = [jsonData inaStringForKey:@"headsign"];
	_numStops       = [jsonData inaIntegerForKey:@"num_stops"];
}

@end

//////////////////////////////////////////////
// NavTransitStop

@implementation NavTransitStop

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavTransitStop alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_name       = [jsonData inaStringForKey:@"name"];
	_location   = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"location"]];
}

@end

//////////////////////////////////////////////
// NavTransitLine

@implementation NavTransitLine

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavTransitLine alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_name       = [jsonData inaStringForKey:@"name"];
	_shortName  = [jsonData inaStringForKey:@"short_name"];
	_color      = [jsonData inaStringForKey:@"color"];
	_textColor  = [jsonData inaStringForKey:@"text_color"];
	_vehicle    = [NavTransitVehicle createFromJsonData:[jsonData inaDictForKey:@"vehicle"]];
	_agencies   = [NavTransitAgency createListFromJsonList:[jsonData inaArrayForKey:@"agencies"]];
}

@end

//////////////////////////////////////////////
// NavTransitVehicle

@implementation NavTransitVehicle

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavTransitVehicle alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_name       = [jsonData inaStringForKey:@"name"];
	_icon       = [jsonData inaStringForKey:@"icon"];
	_type       = [jsonData inaStringForKey:@"type"];
}

@end

//////////////////////////////////////////////
// NavTransitAgency

@implementation NavTransitAgency

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavTransitAgency alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_name       = [jsonData inaStringForKey:@"name"];
	_phone      = [jsonData inaStringForKey:@"phone"];
	_url        = [jsonData inaStringForKey:@"url"];
}

+ (NSArray<NavTransitAgency*>*)createListFromJsonList:(NSArray*)jsonList {
	NSMutableArray<NavTransitAgency*>* result = nil;
	if (jsonList != nil) {
		result = [[NSMutableArray<NavTransitAgency*> alloc] init];
		for (NSDictionary *dict in jsonList) {
			if ([dict isKindOfClass:[NSDictionary class]]) {
				NavTransitAgency* value = [NavTransitAgency createFromJsonData:dict];
				if (value != nil) {
					[result addObject: value];
				}
			}
		}
	}
	return result;
}

@end

//////////////////////////////////////////////
// NavTravelMode

NSString* kNavTravelModeWalking   = @"walking";
NSString* kNavTravelModeBicycling = @"bicycling";
NSString* kNavTravelModeDriving   = @"driving";
NSString* kNavTravelModeTransit   = @"transit";

//////////////////////////////////////////////
// NavCoord

@implementation NavCoord

- (instancetype)initWithLatitude:(double)latitude longitude:(double)longitude {
	if(self = [self init]) {
		_latitude		= latitude;
		_longitude		= longitude;
	}
	return self;
}

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		_latitude		= [jsonData inaDoubleForKey:@"lat"];
		_longitude		= [jsonData inaDoubleForKey:@"lng"];
	}
	return self;
}

- (instancetype)initWithLocation:(CLLocation*)location {
	if(self = [self init]) {
		self.coordinate		= location.coordinate;
	}
	return self;
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
	if(self = [self init]) {
		self.coordinate		= coordinate;
	}
	return self;
}

+ (instancetype)createWithLatitude:(double)latitude longitude:(double)longitude {
	return [[NavCoord alloc] initWithLatitude:latitude longitude:longitude];
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavCoord alloc] initWithJsonData:jsonData] : nil;
}

+ (instancetype)createWithLocation:(CLLocation*)location {
	return (location != nil) ? [[NavCoord alloc] initWithLocation:location] : nil;
}

+ (instancetype)createWithCoordinate:(CLLocationCoordinate2D)coordinate {
	return [[NavCoord alloc] initWithCoordinate:coordinate];
}

- (CLLocationCoordinate2D)coordinate {
	return CLLocationCoordinate2DMake(_latitude, _longitude);
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
	_latitude  = coordinate.latitude;
	_longitude = coordinate.longitude;
}

+ (NSMutableArray*)createListFromEncodedString:(NSString*)encodedString {
	return navCreatePolygonFromEncodedString(encodedString);
}

- (bool)isEqualToCoord:(NavCoord*)navCoord {
	if (self != nil)
		return (navCoord != nil) && CLLocationCoordinate2DIsEqual(self.coordinate, navCoord.coordinate);
	else
		return (navCoord == nil);
}


@end


//////////////////////////////////////////////
// NavBounds

@implementation NavBounds

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavBounds alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_northeast = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"northeast"]];
	_southwest = [NavCoord createFromJsonData:[jsonData inaDictForKey:@"southwest"]];
}

@end

//////////////////////////////////////////////
// NavPolyline

@implementation NavPolyline

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavPolyline alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_points = [jsonData inaStringForKey:@"points"];
}

- (NSArray<NavCoord*>*) coordinates {
	return [NavCoord createListFromEncodedString:_points];
}

@end

//////////////////////////////////////////////
// NavIntVal

@implementation NavIntVal

- (instancetype)initWithJsonData:(NSDictionary*)jsonData {
	if(self = [self init]) {
		[self applyJsonData:jsonData];
	}
	return self;
}

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavIntVal alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	_value = [jsonData inaIntegerForKey:@"value"];
	_text  = [jsonData inaStringForKey:@"text"];
}

@end

//////////////////////////////////////////////
// NavTimeVal

@implementation NavTimeVal

+ (instancetype)createFromJsonData:(NSDictionary*)jsonData {
	return (jsonData != nil) ? [[NavTimeVal alloc] initWithJsonData:jsonData] : nil;
}

- (void)applyJsonData:(NSDictionary*)jsonData {
	[super applyJsonData:jsonData];
	
	_timeZone  = [jsonData inaStringForKey:@"time_zone"];
}

@end
