//
//  RegionMonitor.m
//  Runner
//
//  Created by Mihail Varbanov on 12/11/19.
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

#import "RegionMonitor.h"
#import "RokwirePlugin.h"

#import "NSDictionary+RokwireTypedValue.h"
#import "NSString+RokwireJson.h"

#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, InsideRegionSource) {
	InsideRegionSource_Region,
	InsideRegionSource_Location,
};

@interface RegionMonitor()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager*    locationManager;
@property (nonatomic, strong) NSMutableDictionary*  regions;
@property (nonatomic, strong) NSMutableDictionary*  currentRegionIds;
@property (nonatomic, strong) NSMutableDictionary*  currentRegionBeacons;
@property (nonatomic)         bool                  monitoringLocation;
@end

@interface _Region : NSObject
@property (nonatomic, strong, readonly) NSDictionary*     jsonData;
@property (nonatomic, strong, readonly) NSString*         regionId;
@property (nonatomic, strong, readonly) CLRegion*         clRegion;

@property (nonatomic, assign, readonly) bool              canMonitor;
@property (nonatomic, assign, readonly) bool              canRange;

@property (nonatomic, strong, readonly) CLCircularRegion* clCircularRegion;
@property (nonatomic, assign, readonly) bool              isCircularRegion;

@property (nonatomic, strong, readonly) CLBeaconRegion*   clBeaconRegion;
@property (nonatomic, assign, readonly) bool              isBeaconRegion;

@property (nonatomic)                   bool              monitoring;
@property (nonatomic)                   bool              ranging;

- (id)initWithJsonData:(NSDictionary*)jsonData;
@end

@interface CLBeacon(UIUC)
@property (nonatomic, readonly) NSDictionary* uiucJson;
- (bool)uiucIsEqualToBeacon:(CLBeacon*)beacon;
+ (bool)uiucBeaconsList:(NSArray<CLBeacon*>*)beaconsList1 equalsToBeaconsList:(NSArray<CLBeacon*>*)beaconsList2;
@end

///////////////////////////////////////////
// RegionMonitor

@implementation RegionMonitor

+ (instancetype)sharedInstance {
    static RegionMonitor *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
	
    return _sharedInstance;
}

- (instancetype)init {
	if (self = [super init]) {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // kCLLocationAccuracyNearestTenMeters;
		//_locationManager.allowsBackgroundLocationUpdates = TRUE;

		_regions = [[NSMutableDictionary alloc] init];
		_currentRegionIds = [[NSMutableDictionary alloc] init];
		_currentRegionBeacons = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark FlutterPlugin

- (void)handleMethodCallWithName:(NSString*)name parameters:(id)parameters result:(FlutterResult)result {

	if ([name isEqualToString:@"currentRegions"]) {
		result(self.currentRegionIdsList);
	}
	else if ([name isEqualToString:@"monitorRegions"]) {
		NSArray *regions = [parameters isKindOfClass:[NSArray class]] ? parameters : nil;
		[self monitorRegions:regions];
		result(nil);
	}
	else if ([name isEqualToString:@"startRangingBeaconsInRegion"]) {
		NSString *regionId = [parameters isKindOfClass:[NSString class]] ? parameters : nil;
		result(@([self startRangingBeaconsInRegionWithId:regionId]));
	}
	else if ([name isEqualToString:@"stopRangingBeaconsInRegion"]) {
		NSString *regionId = [parameters isKindOfClass:[NSString class]] ? parameters : nil;
		result(@([self stopRangingBeaconsInRegionWithId:regionId]));
	}
	else if ([name isEqualToString:@"beaconsInRegion"]) {
		NSString *regionId = [parameters isKindOfClass:[NSString class]] ? parameters : nil;
		result([self beaconsInRegionWithId:regionId]);
	}
	else {
		result(nil);
	}
}

- (void)monitorRegions:(NSArray*)regions {

	NSInteger currentRegionsCount = _currentRegionIds.count;

	NSMutableSet *regionsSet = [[NSMutableSet alloc] init];
	for (NSDictionary* regionJson in regions) {
		_Region *region = [[_Region alloc] initWithJsonData:regionJson];
		if (region.regionId != nil) {
			if (_regions[region.regionId] == nil) {
				_regions[region.regionId] = region;
				[self startMonitorRegion:region];
			}
			[regionsSet addObject:region.regionId];
		}
	}
	
	NSMutableSet *removeRegionIds = [[NSMutableSet alloc] init];
	for (NSString *regionId in _regions) {
		if (![regionsSet containsObject:regionId]) {
			[removeRegionIds addObject:regionId];

			_Region *region = [_regions rokwireObjectForKey:regionId class:[_Region class]];
			[self stopMonitorRegion:region];
			[self stopRangingBeaconsInRegion:region];
		}
	}
	
	for (NSString *regionId in removeRegionIds) {
		[_regions removeObjectForKey:regionId];
	}
	
	[self updateLocationMonitor];
	
	if (currentRegionsCount != _currentRegionIds.count) {
		[self _notifyCurrentRegions];
	}
}

- (void)updateRegionMonitor {
	for (NSString *regionId in _regions) {
		_Region *region = [_regions rokwireObjectForKey:regionId class:[_Region class]];
		bool canMonitorRegion = region.canMonitor;
		if (!region.monitoring && canMonitorRegion) {
			[self startMonitorRegion:region];
		}
		else if (region.monitoring && !canMonitorRegion) {
			[self stopMonitorRegion:region];
			[self stopRangingBeaconsInRegion:region];
		}
	}
}
 
- (void)updateLocationMonitor {
	bool hasLocationRegions = [self hasLocationRegions];
	if (hasLocationRegions && !_monitoringLocation && self.canMonitorLocation) {
		[_locationManager startUpdatingLocation];
		_monitoringLocation = true;
	}
	else if (!hasLocationRegions && _monitoringLocation) {
		[_locationManager stopUpdatingLocation];
		_monitoringLocation = false;
	}
}

- (void)startMonitorRegion:(_Region*)region {
	if (region.canMonitor && !region.monitoring) {
		[_locationManager startMonitoringForRegion:region.clRegion];
		region.monitoring = true;
	}
}

- (void)stopMonitorRegion:(_Region*)region {
	if (region.monitoring) {
		[_locationManager stopMonitoringForRegion:region.clRegion];
		region.monitoring = false;
		[_currentRegionIds removeObjectForKey:region.regionId];
	}
}

- (NSArray*)beaconsInRegionWithId:(NSString*)regionId {
	NSArray *beacons = [_currentRegionBeacons rokwireObjectForKey:regionId class:[NSArray class]];
	NSMutableArray *beaconsJson = (beacons != nil) ? [[NSMutableArray alloc] init] : nil;
	for (CLBeacon *beacon in beacons) {
		[beaconsJson addObject:beacon.uiucJson];
	}
	return beaconsJson;
}


- (bool)startRangingBeaconsInRegionWithId:(NSString*)regionId {
	_Region *region = [_regions rokwireObjectForKey:regionId class:[_Region class]];
	NSNumber *currentRegionSource = [_currentRegionIds rokwireNumberForKey:regionId];
	bool insideRegion = (currentRegionSource != nil) && (currentRegionSource.integerValue == InsideRegionSource_Region);
	if (insideRegion && !region.ranging && region.isBeaconRegion && region.canRange) {
		[_locationManager startRangingBeaconsInRegion:region.clBeaconRegion];
		region.ranging = true;
		return true;
	}
	return false;
}

- (bool)stopRangingBeaconsInRegionWithId:(NSString*)regionId {
	if (regionId != nil) {
		_Region *region = (regionId != nil) ? [_regions rokwireObjectForKey:regionId class:[_Region class]] : nil;
		return [self stopRangingBeaconsInRegion:region];
	}
	else {
		[self stopAllRangingBeacons];
		return true;
	}
}

- (bool)stopRangingBeaconsInRegion:(_Region*)region {
	NSString *regionId = region.regionId;
	if (region.ranging && region.isBeaconRegion) {
		[_locationManager stopRangingBeaconsInRegion:region.clBeaconRegion];
		region.ranging = false;

		if ([_currentRegionBeacons objectForKey:regionId] != nil) {
			[_currentRegionBeacons removeObjectForKey:regionId];
			[self _notifyBeacons:nil forRegionWithId:regionId];
		}
		return true;
	}
	return false;
}

- (void)stopAllRangingBeacons {
	for (NSString *regionId in _regions) {
		[self stopRangingBeaconsInRegionWithId:regionId];
	}
}

- (void)didRangeBeacons:(NSArray<CLBeacon*>*)beacons forRegion:(CLBeaconRegion*)region {

	NSString *regionId = region.identifier;
	NSArray *currentBeacons = [_currentRegionBeacons rokwireObjectForKey:regionId class:[NSArray class]];
	
	if (![CLBeacon uiucBeaconsList:currentBeacons equalsToBeaconsList:beacons]) {
		if (beacons != nil) {
			[_currentRegionBeacons setObject:beacons forKey:regionId];
		}
		else {
			[_currentRegionBeacons removeObjectForKey:regionId];
		}
	
		NSMutableArray *beaconsJson = (beacons != nil) ? [[NSMutableArray alloc] init] : nil;
		for (CLBeacon *beacon in beacons) {
			[beaconsJson addObject:beacon.uiucJson];
		}

		[self _notifyBeacons:beaconsJson forRegionWithId:regionId];
	}
}

- (NSArray*)currentRegionIdsList {
	NSMutableArray *currentIds = [[NSMutableArray alloc] init];
	for (NSString *regionId in _currentRegionIds) {
		[currentIds addObject:regionId];
	}
	return currentIds;
}

- (bool)hasLocationRegions {
	for (NSString *regionId in _regions) {
		_Region *region = [_regions rokwireObjectForKey:regionId class:[_Region class]];
		if (region.isCircularRegion) {
			return true;
		}
	}
	return false;
}

- (bool)canMonitorLocation {
	return [CLLocationManager locationServicesEnabled] && (
		([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) ||
		([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse));
}

- (void)_notifyCurrentRegions {
	[RokwirePlugin.sharedInstance notifyGeoFenceEvent:@"onCurrentRegionsChanged" arguments:self.currentRegionIdsList];
}

- (void)_notifyRegionEnter:(NSString*)regionId {
	[RokwirePlugin.sharedInstance notifyGeoFenceEvent:@"onEnterRegion" arguments:regionId];
}

- (void)_notifyRegionExit:(NSString*)regionId {
	[RokwirePlugin.sharedInstance notifyGeoFenceEvent:@"onExitRegion" arguments:regionId];
}

- (void)_notifyBeacons:(NSArray*)beacons forRegionWithId:(NSString*)regionId {
	[RokwirePlugin.sharedInstance notifyGeoFenceEvent:@"onBeaconsInRegionChanged" arguments:@{
		@"regionId": regionId ?: [NSNull null],
		@"beacons": beacons ?: [NSNull null],
	}];
}

#pragma mark CLLocationManagerDelegate / Regions

- (void)locationManager:(CLLocationManager*)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)clRegion {
	NSString *regionId = clRegion.identifier;
	NSLog(@"RegionMonotor didDetermineState: %@ forRegion: %@", @(state), regionId);
	
	bool modified = false;
	if (state == CLRegionStateInside) {

		NSLog(@"RegionMonotor region inside: %@", regionId);
		modified = ([_currentRegionIds objectForKey:regionId] == nil);
		[_currentRegionIds setObject:@(InsideRegionSource_Region) forKey:regionId];
		if (modified) {
			[self _notifyRegionEnter:regionId];
			[self _notifyCurrentRegions];
		}
	}
	else if (state == CLRegionStateOutside) {

		NSLog(@"RegionMonotor region outside: %@", regionId);
		modified = ([_currentRegionIds objectForKey:regionId] != nil);
		[_currentRegionIds removeObjectForKey:regionId];
		if (modified) {
			[self _notifyRegionExit:regionId];
			[self _notifyCurrentRegions];
		}
		
		if ([clRegion isKindOfClass:[CLBeaconRegion class]]) {
			[self stopRangingBeaconsInRegionWithId:regionId];;
		}
	}
}

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)clRegion {
	NSString *regionId = clRegion.identifier;
	NSLog(@"RegionMonotor didEnterRegion: %@", regionId);
	NSLog(@"RegionMonotor region inside: %@", regionId);

	bool modified = ([_currentRegionIds objectForKey:regionId] == nil);
	[_currentRegionIds setObject:@(InsideRegionSource_Region) forKey:regionId];
	if (modified) {
		[self _notifyRegionEnter:regionId];
		[self _notifyCurrentRegions];
	}
}

- (void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)clRegion {
	NSString *regionId = clRegion.identifier;
	NSLog(@"RegionMonotor didExitRegion: %@", regionId);
	NSLog(@"RegionMonotor region outside: %@", regionId);

	bool modified = ([_currentRegionIds objectForKey:regionId] != nil);
	[_currentRegionIds removeObjectForKey:regionId];
	if (modified) {
		[self _notifyRegionExit:regionId];
		[self _notifyCurrentRegions];
	}

	if ([clRegion isKindOfClass:[CLBeaconRegion class]]) {
		[self stopRangingBeaconsInRegionWithId:regionId];
	}
}

- (void)locationManager:(CLLocationManager*)manager monitoringDidFailForRegion:(CLRegion*)clRegion withError:(NSError*)error {
	NSLog(@"RegionMonotor monitoringDidFailForRegion: %@ withError: %@", clRegion.identifier, error.debugDescription);
}

#pragma mark CLLocationManagerDelegate / Location

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	CLLocation* location = [locations lastObject];
	//NSLog(@"RegionMonotor didUpdateLocation: [%.6f, %.6f]", location.coordinate.latitude, location.coordinate.longitude);
	
	bool modified = false;
	for (NSString *regionId in _regions) {
		_Region *region = [_regions rokwireObjectForKey:regionId class:[_Region class]];
		NSNumber *currentRegionSource = [_currentRegionIds rokwireNumberForKey:regionId];
		if ([region.clCircularRegion containsCoordinate:location.coordinate]) {
			if (currentRegionSource == nil) {
				NSLog(@"RegionMonotor location inside: %@", regionId);
				[_currentRegionIds setObject:@(InsideRegionSource_Location) forKey:regionId];
				[self _notifyRegionEnter:regionId];
				modified = true;
			}
		}
		else {
			if ((currentRegionSource != nil) && (currentRegionSource.integerValue == InsideRegionSource_Location)) {
				NSLog(@"RegionMonotor location outside: %@", regionId);
				[_currentRegionIds removeObjectForKey:regionId];
				[self _notifyRegionExit:regionId];
				modified = true;
			}
		}
	}
	if (modified) {
		[self _notifyCurrentRegions];
	}
}

- (void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError *)error {
	NSLog(@"RegionMonotor didFailWithError: %@", error.localizedDescription);
}

#pragma mark CLLocationManagerDelegate / Beacons

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon*>*)beacons inRegion:(CLBeaconRegion *)clBeaconRegion {
	NSString *regionId = clBeaconRegion.identifier;
	NSLog(@"RegionMonotor didRangeBeacons:[<%@>] inRegion: %@", @(beacons.count), regionId);
	
	[self didRangeBeacons:beacons forRegion:clBeaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)clBeaconRegion withError:(NSError *)error {
	NSString *regionId = clBeaconRegion.identifier;
	NSLog(@"RegionMonotor rangingBeaconsDidFailForRegion: %@ withError: %@", regionId, error.localizedDescription);

	[self stopRangingBeaconsInRegionWithId:regionId];
}

#pragma mark CLLocationManagerDelegate / Authorization

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	NSLog(@"RegionMonotor didChangeAuthorizationStatus: %@", @(status));
	[self updateRegionMonitor];
	[self updateLocationMonitor];
}

@end

///////////////////////////////////////////
// _Region

@implementation _Region

- (id)initWithJsonData:(NSDictionary*)jsonData {
	if (self = [super init]) {
		_jsonData = jsonData;
		
		NSString *regionId = [_jsonData rokwireStringForKey:@"id"];
		
		NSDictionary *data;
		if ((data = [_jsonData rokwireDictForKey:@"location"]) != nil) {
			CLLocationDegrees latitude = [data rokwireDoubleForKey:@"latitude"];
			CLLocationDegrees longitude = [data rokwireDoubleForKey:@"longitude"];
			CLLocationDistance radius = [data rokwireDoubleForKey:@"radius"];
			CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
			_clRegion = [[CLCircularRegion alloc] initWithCenter:coordinate radius:radius identifier:regionId];
		}
		else if ((data = [_jsonData rokwireDictForKey:@"beacon"]) != nil) {
			NSString *uuidString = [data rokwireStringForKey:@"uuid"];
			NSUUID *uuid = (uuidString != nil) ? [[NSUUID alloc] initWithUUIDString:uuidString] : nil;
			NSNumber *major = [data rokwireNumberForKey:@"major"];
			NSNumber *minor = [data rokwireNumberForKey:@"minor"];
			if ((uuid != nil) && (major != nil) && (minor != nil)) {
				_clRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:minor.unsignedShortValue minor:minor.unsignedShortValue identifier:regionId];
			}
			else if ((uuid != nil) && (major != nil)) {
				_clRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:minor.unsignedShortValue identifier:regionId];
			}
			else if (uuid != nil) {
				_clRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:regionId];
			}
		}
	}
	return self;
}

- (NSString*)regionId {
	return _clRegion.identifier;
}

- (bool)canMonitor {
	return
		[CLLocationManager locationServicesEnabled] &&
		/*(([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) ||
		   ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) &&*/
		[CLLocationManager isMonitoringAvailableForClass:self.clRegion.class];

}

- (bool)canRange {
	return [CLLocationManager isRangingAvailable];
}

- (bool)isCircularRegion {
	return [_clRegion isKindOfClass:[CLCircularRegion class]];
}

- (CLCircularRegion*)clCircularRegion {
	return [_clRegion isKindOfClass:[CLCircularRegion class]] ? ((CLCircularRegion*)_clRegion) : nil;
}

- (bool)isBeaconRegion {
	return [_clRegion isKindOfClass:[CLBeaconRegion class]];
}

- (CLBeaconRegion*)clBeaconRegion {
	return [_clRegion isKindOfClass:[CLBeaconRegion class]] ? ((CLBeaconRegion*)_clRegion) : nil;
}

@end

///////////////////////////////////////////
// CLBeacon+UIUC

@implementation CLBeacon(UIUC)

- (NSDictionary*)uiucJson {
	return @{
		@"uuid": self.proximityUUID.UUIDString ?: [NSNull null],
		@"major": self.major ?: [NSNull null],
		@"minor": self.minor ?: [NSNull null]
	};
}

- (bool)uiucIsEqualToBeacon:(CLBeacon*)beacon {
	return
		[self.proximityUUID isEqual:beacon.proximityUUID] &&
		[self.major isEqual:beacon.major] &&
		[self.minor isEqual:beacon.minor];
}

+ (bool)uiucBeaconsList:(NSArray<CLBeacon*>*)beaconsList1 equalsToBeaconsList:(NSArray<CLBeacon*>*)beaconsList2 {
	if (beaconsList1.count != beaconsList2.count) {
		return false;
	}
	for (NSInteger index = 0; index < beaconsList1.count; index++) {
		CLBeacon *beacon1 = [beaconsList1 objectAtIndex:index];
		CLBeacon *beacon2 = [beaconsList2 objectAtIndex:index];
		if (![beacon1 uiucIsEqualToBeacon:beacon2]) {
			return false;
		}
	}
	return true;
}

@end
