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

#import "NSDictionary+UIUCExplore.h"

#import "NSDictionary+InaTypedValue.h"
#import "NSDictionary+InaPathKey.h"
#import "NSDate+InaUtils.h"
#import "NSDate+UIUCUtils.h"

@implementation NSDictionary(UIUCExplore)

- (UIUCExploreType)uiucExploreType {
	if ([self objectForKey:@"eventId"] != nil) {
		return UIUCExploreType_Event;
	}
	else if ([self objectForKey:@"DiningOptionID"] != nil) {
		return UIUCExploreType_Dining;
	}
	else if ([self objectForKey:@"campus_name"] != nil) {
		return UIUCExploreType_Laundry;
	}
	else if ([self objectForKey:@"lot_id"] != nil) {
		return UIUCExploreType_Parking;
	}
	else if ([self objectForKey:@"entrances"] != nil) {
		return UIUCExploreType_Building;
	}
	else if ([self objectForKey:@"coursetitle"] != nil) {
		return UIUCExploreType_StudentCourse;
	}
	else if ([self objectForKey:@"source_id"] != nil) {
		return UIUCExploreType_Appointment;
	}
	else if ([self objectForKey:@"stop_id"] != nil) {
		return UIUCExploreType_MTDStop;
	}
	else if ([self objectForKey:@"placeId"] != nil) {
		return UIUCExploreType_POI;
	}
	else if ([self objectForKey:@"explores"] != nil) {
		return UIUCExploreType_Explores;
	}
	else {
		return UIUCExploreType_Unknown;
	}
}

- (UIUCExploreType)uiucExploreContentType {
	return [self inaIntegerForKey:@"exploresContentType" defaults:UIUCExploreType_Unknown];
}

- (NSString*)uiucExploreMarkerHexColor {
	UIUCExploreType exploreType = self.uiucExploreType;
	return (exploreType == UIUCExploreType_Explores) ?
		[self inaStringForKey:@"color" defaults:@"#13294b"] :
		[self.class uiucExploreMarkerHexColorFromType:exploreType];
}

+ (NSString*)uiucExploreMarkerHexColorFromType:(UIUCExploreType)type {
	switch (type) {
		case UIUCExploreType_Event:   return @"#e84a27"; // illinoisOrange
		case UIUCExploreType_Dining:  return @"#f29835"; // mangо
		case UIUCExploreType_MTDStop: return @"#2376e5"; // blue
		case UIUCExploreType_POI:     return @"#2376e5"; // blue
		default:                      return @"#5fa7a3"; // teal
	}
}

- (NSString*)uiucExploreTitle {
	switch (self.uiucExploreType) {
		case UIUCExploreType_Parking:       return [self inaStringForKey:@"lot_name"];
		case UIUCExploreType_Building:      return [self inaStringForKey:@"name"];
		case UIUCExploreType_StudentCourse: return [self inaStringForKey:@"coursetitle"];
		case UIUCExploreType_MTDStop:       return [self inaStringForKey:@"stop_name"];
		case UIUCExploreType_POI:           return [self inaStringForKey:@"name"];
		default:                            return [self inaStringForKey:@"title"];
	}
}

- (NSString*)uiucExploreDescription {
	UIUCExploreType exploreType = self.uiucExploreType;
	if (exploreType == UIUCExploreType_Event) {
		NSString *eventTime = [self inaStringForKey:@"startDateLocal"];
		if (0 < eventTime.length) {
			NSDate *eventDate = [NSDate inaDateFromString:eventTime format:@"yyyy-MM-dd'T'HH:mm:ss"];
			return [eventDate formatUUICTime] ?: eventTime;
		}
	}
	else if (exploreType == UIUCExploreType_Laundry) {
		return [self inaStringForKey:@"status"];
	}
	else if (exploreType == UIUCExploreType_Building) {
		return [self inaStringForKey:@"address1"];
	}
	else if (exploreType == UIUCExploreType_StudentCourse) {
		NSMutableString *result = [[NSMutableString alloc] init];
		NSDictionary *secton = [self inaDictForKey:@"coursesection"];

		NSString *buildingName = [secton inaStringForKey:@"buildingname"];
		if (0 < buildingName.length) {
			if (0 < result.length) {
				[result appendString: @", "];
			}
			[result appendString: buildingName];
		}
		
		NSString *room = [secton inaStringForKey:@"room"];
		if (0 < room.length) {
			if (0 < result.length) {
				[result appendString: @", "];
			}
			
			[result appendFormat: NSLocalizedString(@"Room %@", nil), room];
		}
	
		return result;
	}
	else if (exploreType == UIUCExploreType_MTDStop) {
		return [self inaStringForKey:@"code"];
	}
	else if (exploreType == UIUCExploreType_Appointment) {
		NSDictionary *location = [self inaDictForKey:@"location"];
		return [location inaStringForKey:@"title"];
	}
	else if (exploreType == UIUCExploreType_POI) {
		CLLocationCoordinate2D location = self.uiucExploreLocationCoordinate;
		return CLLocationCoordinate2DIsValid(location) ? [NSString stringWithFormat:@"[%.6f, %.6f]", location.latitude, location.longitude] : nil;
	}
	
	return [self.uiucExploreLocation inaStringForKey:@"description"];
}

- (NSArray*)uiucExplores {
	return [self inaArrayForKey:@"explores"];
}

- (NSDictionary*)uiucExploreLocation {
	switch (self.uiucExploreType) {
		case UIUCExploreType_StudentCourse:  return [self inaDictForPathKey:@"coursesection.building"];
		case UIUCExploreType_Building:       return self;
		case UIUCExploreType_MTDStop:        return self;
		case UIUCExploreType_Parking:        return [self inaDictForKey:@"entrance"];
		default:                             return [self inaDictForKey:@"location"];
	}
}

- (NSDictionary*)uiucExploreDestinationLocation {
	switch (self.uiucExploreType) {
		case UIUCExploreType_StudentCourse: {
			NSDictionary *building = [self inaDictForPathKey:@"coursesection.building"];
			NSArray *entrances = [building inaArrayForKey:@"entrances"];
			NSDictionary *entrance = entrances.firstObject;
			return [entrance isKindOfClass: [NSDictionary class]] ? entrance : building;
		}
		case UIUCExploreType_Building:       return self;
		case UIUCExploreType_MTDStop:        return self;
		case UIUCExploreType_Parking:        return [self inaDictForKey:@"entrance"];
		default:														 return [self inaDictForKey:@"location"];
	}
}

- (NSString*)uiucExploreAddress {
	switch (self.uiucExploreType) {
		case UIUCExploreType_Parking:        return [self inaStringForKey:@"lot_address1"];
		case UIUCExploreType_Building:       return [self inaStringForKey:@"address1"];
		case UIUCExploreType_StudentCourse:  return [self inaStringForPathKey:@"coursesection.building.address1"];
		case UIUCExploreType_Explores:       return [self inaStringForKey:@"address"];
		default:                             return nil;
	}
}

- (NSArray*)uiucExplorePolygon {
	return [self inaArrayForKey:@"polygon"];
}

- (CLLocationCoordinate2D)uiucExploreLocationCoordinate {
	return self.uiucExploreLocation.uiucLocationCoordinate;
}

- (CLLocationCoordinate2D)uiucLocationCoordinate {
	NSString *latKey = nil, *lonKey = nil;
	switch (self.uiucExploreType) {
		case UIUCExploreType_MTDStop: latKey = @"stop_lat"; lonKey = @"stop_lon"; break;
		default:                      latKey = @"latitude"; lonKey = @"longitude"; break;
	}
	NSNumber *latitude = [self inaNumberForKey:latKey];
	NSNumber *longitude = [self inaNumberForKey:lonKey];
	return ((latitude != nil) && (longitude != nil) && ((longitude.doubleValue != 0.0) || (longitude.doubleValue != 0.0))) ?
		CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue) : kCLLocationCoordinate2DInvalid;
}

- (int)uiucExploreLocationFloor {
	NSDictionary *location = self.uiucExploreLocation;
	return [location inaIntForKey:@"floor"];
}

+ (NSDictionary*)uiucExploreFromGroup:(NSArray*)explores {
	if ((explores != nil) && (1 < explores.count)) {
		
		UIUCExploreType exploresType = UIUCExploreType_Unknown;
    double x = 0, y = 0, z = 0;

		for (NSDictionary *explore in explores) {
			UIUCExploreType exploreType = explore.uiucExploreType;
			if (exploresType == UIUCExploreType_Unknown) {
				exploresType = exploreType;
			}
			else if (exploresType != exploreType) {
				exploresType = UIUCExploreType_Unknown;
			}
			
	    // https://stackoverflow.com/a/60163851/3759472
			CLLocationCoordinate2D exploreCoord = explore.uiucExploreLocationCoordinate;
      double latitude = exploreCoord.latitude * M_PI / 180;
      double longitude = exploreCoord.longitude * M_PI / 180;
      double c1 = cos(latitude);
      x = x + c1 * cos(longitude);
      y = y + c1 * sin(longitude);
      z = z + sin(latitude);
		}
		
    x = x / explores.count;
    y = y / explores.count;
    z = z / explores.count;

    double centralLongitude = atan2(y, x);
    double centralSquareRoot = sqrt(x * x + y * y);
    double centralLatitude = atan2(z, centralSquareRoot);
    CLLocationCoordinate2D exploresCoord = CLLocationCoordinate2DMake(centralLatitude * 180 / M_PI, centralLongitude * 180 / M_PI);

		NSString *exploresName = nil;
		switch (exploresType) {
			case UIUCExploreType_Event:         exploresName = @"Events"; break;
			case UIUCExploreType_Dining:        exploresName = @"Dinings"; break;
			case UIUCExploreType_Laundry:       exploresName = @"Laundries"; break;
			case UIUCExploreType_Parking:       exploresName = @"Parkings"; break;
			case UIUCExploreType_Building:      exploresName = @"Buildings"; break;
			case UIUCExploreType_MTDStop:       exploresName = @"Stops"; break;
			case UIUCExploreType_StudentCourse: exploresName = @"Courses"; break;
			case UIUCExploreType_Appointment:   exploresName = @"Appointments"; break;
			case UIUCExploreType_POI:           exploresName = @"Locations"; break;
			default:                            exploresName = @"Explores"; break;
		}
		
		NSString *exploresColor = (exploresType != UIUCExploreType_Unknown) ? [self.class uiucExploreMarkerHexColorFromType:exploresType] : @"#13294b";
		
		return @{
			@"type" : @"explores",
			@"title" : [NSString stringWithFormat:@"%d %@", (int)explores.count, exploresName],
			@"location" : @{
				@"latitude": @(exploresCoord.latitude),
				@"longitude" : @(exploresCoord.longitude)
			},
			@"address": [NSNull null],
			@"color": exploresColor,
			@"exploresContentType": @(exploresType),
			@"explores" : explores,
		};
	}
	return nil;
}

@end

// UIUCExploreType

NSString* UIUCExploreTypeToString(UIUCExploreType exploreType) {
	switch (exploreType) {
		case UIUCExploreType_Event:         return @"event";
		case UIUCExploreType_Dining:        return @"dining";
		case UIUCExploreType_Laundry:       return @"laundry";
		case UIUCExploreType_Parking:       return @"parking";
		case UIUCExploreType_Building:      return @"building";
		case UIUCExploreType_MTDStop:       return @"mtd_stop";
		case UIUCExploreType_StudentCourse: return @"studnet_course";
		case UIUCExploreType_POI:           return @"poi";
		case UIUCExploreType_Explores:      return @"explores";
		default: return nil;
	}
}

UIUCExploreType UIUCExploreTypeFromString(NSString* value) {
	if (value != nil) {
		if ([value isEqualToString:@"event"]) {
			return UIUCExploreType_Event;
		}
		else if ([value isEqualToString:@"dining"]) {
			return UIUCExploreType_Dining;
		}
		else if ([value isEqualToString:@"laundry"]) {
			return UIUCExploreType_Laundry;
		}
		else if ([value isEqualToString:@"parking"]) {
			return UIUCExploreType_Parking;
		}
		else if ([value isEqualToString:@"building"]) {
			return UIUCExploreType_Building;
		}
		else if ([value isEqualToString:@"mtd_stop"]) {
			return UIUCExploreType_MTDStop;
		}
		else if ([value isEqualToString:@"studnet_course"]) {
			return UIUCExploreType_StudentCourse;
		}
		else if ([value isEqualToString:@"poi"]) {
			return UIUCExploreType_POI;
		}
		else if ([value isEqualToString:@"explores"]) {
			return UIUCExploreType_Explores;
		}
	}
	return UIUCExploreType_Unknown;
}
