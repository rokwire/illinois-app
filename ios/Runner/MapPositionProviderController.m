//
//  MapPositionProviderController.m
//  Runner
//
//  Created by Mihail Varbanov on 7/11/19.
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

#import "MapPositionProviderController.h"
#import "AppDelegate.h"
#import "AppKeys.h"
#import "MapMarkerView.h"

#import "NSDictionary+UIUCConfig.h"
#import "NSDictionary+InaTypedValue.h"
#import "NSArray+InaTypedValue.h"
#import "NSString+InaJson.h"
#import "NSUserDefaults+InaUtils.h"
#import "UIColor+InaParse.h"
#import "CLLocationCoordinate2D+InaUtils.h"
#import "NSDictionary+UIUCExplore.h"
#import "InaSymbols.h"

#import <Foundation/Foundation.h>


@interface MapPositionProviderController()

@end

/////////////////////////////////
// MapPositionProviderController

@implementation MapPositionProviderController

- (instancetype)init {
	if (self = [super init]) {
		self.navigationItem.title = NSLocalizedString(@"Maps", nil);

		_mrAppKey = [MREditorKey keyWithIdentifier:[AppDelegate.sharedInstance.keys uiucConfigStringForPathKey:@"meridian.app_id"]];
		_mrTimeoutInterval = 10.0;
		_mrSleepInterval = 10.0;

		_mrLocationManager = [[MRLocationManager alloc] initWithApp:_mrAppKey];
		_mrLocationManager.delegate = self;
		
		_clLocationManager = [[CLLocationManager alloc] init];
		_clLocationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
		_clLocationManager.delegate = self;
	}
	return self;
}

- (instancetype)initWithParameters:(NSDictionary*)parameters completionHandler:(FlutterCompletion)completionHandler {
	if (self = [self init]) {
		_parameters = parameters;
		_completionHandler = completionHandler;
	}
	return self;
}

- (void)loadView {

	self.view = [[UIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [UIColor whiteColor];
	
	NSDictionary *target = [_parameters inaDictForKey:@"target"];
	CLLocationDegrees latitude = [target inaDoubleForKey:@"latitude"] ?: kInitialCameraLocation.latitude;
	CLLocationDegrees longitude = [target inaDoubleForKey:@"longitude"] ?: kInitialCameraLocation.longitude;
	float zoom = [target inaFloatForKey:@"zoom"] ?: kInitialCameraZoom;
	
	GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude longitude:longitude zoom:zoom];
	_gmsMapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
	_gmsMapView.delegate = self;
	//_gmsMapView.myLocationEnabled = YES;
	//_gmsMapView.settings.compassButton = YES;
	//_gmsMapView.settings.myLocationButton = YES;
	[self.view addSubview:_gmsMapView];

	_mpMapControl = [[MPMapControl alloc] initWithMap:_gmsMapView];
	_mpMapControl.delegate = self;
	[_mpMapControl showUserPosition:YES];
	
	NSDictionary *options = [_parameters inaDictForKey:@"options"];
	if (options != nil) {
	
		_mpMapControl.floorSelectorHidden = ([options inaBoolForKey:@"enableLevels" defaults:true] == false);
	
		if ([options inaBoolForKey:@"showDebugLocation"]) {
			_debugStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			_debugStatusLabel.font = [UIFont boldSystemFontOfSize:12];
			_debugStatusLabel.textAlignment = NSTextAlignmentCenter;
			_debugStatusLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.5];
			_debugStatusLabel.shadowOffset = CGSizeMake(2, 2);
			[_gmsMapView addSubview:_debugStatusLabel];
		}
	}

	NSArray *markers = [_parameters inaArrayForKey:@"markers"];
	for (NSDictionary *markerJson in markers) {
		if ([markerJson isKindOfClass:[NSDictionary class]]) {
			GMSMarker *marker = [[GMSMarker alloc] init];
			CLLocationDegrees markerLatitude = [markerJson inaDoubleForKey:@"latitude"];
			CLLocationDegrees markerLongitude = [markerJson inaDoubleForKey:@"longitude"];
			marker.position = CLLocationCoordinate2DMake(markerLatitude, markerLongitude);
			marker.title = [markerJson inaStringForKey:@"name"];
			marker.snippet = [markerJson inaStringForKey:@"description"];
			marker.map = _gmsMapView;
		}
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self layoutSubViews];
}

- (void)layoutSubViews {
	CGSize contentSize = self.view.frame.size;
	_gmsMapView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);

	if (_debugStatusLabel != nil) {
		CGFloat labelH = 12;
		_debugStatusLabel.frame = CGRectMake(0, contentSize.height - 1 - labelH, contentSize.width, labelH);
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadMeridianMaps];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self startMonitor];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self stopMonitor];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

#pragma mark Location Provider

- (void)startMonitor {

	if (MapsIndoors.positionProvider != self) {
		_mpLastPositionProvider = MapsIndoors.positionProvider;
		MapsIndoors.positionProvider = self;
	}

	if (!_isRunning) {
		[self startMeridian];
		[self startCoreLocation];
		_isRunning = TRUE;
	}
}

- (void)stopMonitor {

	if (MapsIndoors.positionProvider == self) {
		MapsIndoors.positionProvider = _mpLastPositionProvider;
		_mpLastPositionProvider = nil;
	}

	if (_isRunning) {
		[self stopMeridian];
		[self stopCoreLocation];
		_isRunning = FALSE;
	}
}

#pragma mark Meridian Location

- (void)startMeridian {
	NSLog(@"Meridian Start");
	[_mrLocationManager startUpdatingLocation];
	[self setupMeridianTimeoutTimer];
}

- (void)stopMeridian {
	NSLog(@"Meridian Stop");
	[_mrLocationManager stopUpdatingLocation];
	[self clearMeridianTimer];
	_mrLocation = nil;
	_mrLocationError = nil;
}

- (void)restartMeridian {
	[self stopMeridian];

	NSLog(@"Meridian Sleep");
	[self setupMeridianSleepTimer];

	[self notifyCoreLocationUpdate];
}

- (void)setupMeridianTimeoutTimer {
	[self clearMeridianTimer];

	__weak typeof(self) weakSelf = self;
	_mrTimer = [NSTimer scheduledTimerWithTimeInterval:_mrTimeoutInterval target:weakSelf selector:@selector(onMeridianTimeout) userInfo:nil repeats:NO];
}

- (void)onMeridianTimeout {
	NSLog(@"Meridian Timeout");
	_mrLocationTimeoutsCount++;
	if ((0 < _mrLocationTimeoutsCount) && (_mrLocationError == nil)) {
		_mrLocationError = [NSError errorWithDomain:@"com.illinois.rokwire" code:1 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to detect current location.", nil) }];
		[self notifyLocationFail];
	}
	[self restartMeridian];
}

- (void)setupMeridianSleepTimer {
	[self clearMeridianTimer];

	__weak typeof(self) weakSelf = self;
	_mrTimer = [NSTimer scheduledTimerWithTimeInterval:_mrSleepInterval target:weakSelf selector:@selector(onMeridianSleep) userInfo:nil repeats:NO];
}

- (void)onMeridianSleep {
	NSLog(@"Meridian Awake");
	[self startMeridian];
}

- (void)clearMeridianTimer {
	if (_mrTimer != nil) {
		[_mrTimer invalidate];
		_mrTimer = nil;
	}
}

- (void)notifyMeridianLocationUpdate {

	MRMap *map = ((_mrLocation != nil) && (_mrMaps != nil)) ? [self meridianMapForLocation:_mrLocation] : nil;
	if (map != nil) {
		CLLocationCoordinate2D location2D = [map gpsWithMapPt:_mrLocation.point];
		//static int mrFloors[] = {-10, 0, 20, 30};
		//int mpFloor = mrFloors[map.level];
		int mpFloor = map.level;
		MPPositionResult *positionResult = [[MPPositionResult alloc] init];
		positionResult.geometry = [[MPPoint alloc] initWithLat:location2D.latitude lon:location2D.longitude zValue:mpFloor];
		positionResult.provider = self;
		[self notifyLocationUpdate:positionResult source:MPPositionProviderSource_Meridian];
	}
}

#pragma mark Meridian Maps

- (void)loadMeridianMaps {
	NSLog(@"Meridian: Retriving maps ...");
	
	__weak typeof(self) weakSelf = self;
	[MRMap getMapsForApp:_mrAppKey pageURL:nil
		success:^(NSArray<MRMap *> * _Nonnull maps, NSURL * _Nullable next) {
			NSLog(@"Meridian: Retrivied maps");
			weakSelf.mrMaps = maps;
			if ((weakSelf.mrLocation != nil) && (1 < weakSelf.mrLocationUpdatesCount)) {
				[weakSelf notifyMeridianLocationUpdate];
			}
			else if (weakSelf.clLocation != nil) {
				[weakSelf notifyCoreLocationUpdate];
			}
		}
		failure:^(NSError * _Nonnull error) {
			NSLog(@"Meridian: Failed to retrieve maps: %@", error.localizedDescription);
		}];
}

- (MRMap*)meridianMapForLocation:(MRLocation*)location {
	for (MRMap *map in _mrMaps) {
		if ([map.key.identifier isEqualToString:location.mapKey.identifier]) {
			return map;
		}
	}
	return nil;
}

#pragma mark Core Location

- (void)startCoreLocation {
	[_clLocationManager startUpdatingLocation];
}

- (void)stopCoreLocation {
	[_clLocationManager stopUpdatingLocation];
}

- (void)notifyCoreLocationUpdate {
	if ((_clLocation != nil) &&
		((_mrLocation == nil) || (fabs([_mrLocation.timestamp timeIntervalSinceNow]) > _mrTimeoutInterval))) {
		
		MPPositionResult *positionResult = [[MPPositionResult alloc] init];
		positionResult.geometry = [[MPPoint alloc] initWithLat:_clLocation.coordinate.latitude lon:_clLocation.coordinate.longitude];
		positionResult.provider = self;
		[self notifyLocationUpdate:positionResult source:MPPositionProviderSource_CoreLocation];
	}
}

#pragma mark Location

- (void)notifyLocationUpdate:(MPPositionResult*)positionResult source:(MPPositionProviderSource)source {
	if (positionResult != nil) {
		_mpPositionResult = positionResult;
		_mpPositionProviderSource = source;

		if (_mpPositionProviderDelegate != nil) {
			NSLog(@"MPPositionProviderDelegate onPositionUpdate: [%.6f, %.6f] @ level %d", _mpPositionResult.geometry.lat, _mpPositionResult.geometry.lng, _mpPositionResult.geometry.zIndex);
			[_mpPositionProviderDelegate onPositionUpdate:_mpPositionResult];
			
			if (_debugStatusLabel != nil) {
				NSString *sourceAbbr = nil;
				UIColor  *sourceColor = nil;
				if (_mpPositionProviderSource == MPPositionProviderSource_Meridian) {
					sourceAbbr = @"MR";
					sourceColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1.0];;
				}
				else if (_mpPositionProviderSource == MPPositionProviderSource_CoreLocation) {
					sourceAbbr = @"CL";
					sourceColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1.0];
				}
				else {
					sourceAbbr = @"UNK";
					sourceColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
				}
				
				_debugStatusLabel.text = [NSString stringWithFormat:@"%@ [%.6f, %.6f] @ %d", sourceAbbr, _mpPositionResult.geometry.lat, _mpPositionResult.geometry.lng, _mpPositionResult.geometry.zIndex];
				_debugStatusLabel.textColor = sourceColor;
			}
		}
	}
}

- (void)notifyLocationFail {
	if ((_mrLocationError != nil) && (_clLocationError != nil)) {
		if (_mpPositionProviderDelegate != nil) {
			NSLog(@"MPPositionProviderDelegate onPositionFailed");
			[_mpPositionProviderDelegate onPositionFailed:self];

			if (_debugStatusLabel != nil) {
				_debugStatusLabel.text = [NSString stringWithFormat:@"MR: %@; CL: %@", _mrLocationError.debugDescription, _clLocationError.debugDescription];
				_debugStatusLabel.textColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1.0];
			}
		}
	}
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* location = [locations lastObject];
	NSLog(@"CoreLocation: at location: [%.6f, %.6f]", location.coordinate.latitude, location.coordinate.longitude);

	_clLocation = location;
	_clLocationError = nil;
	
	[self notifyCoreLocationUpdate];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	[self updateLocationPermissionStatus];
}

#pragma mark MRLocationManagerDelegate

- (void)locationManager:(MRLocationManager *)manager didUpdateToLocation:(MRLocation *)location {
	
	MRMap *map = (_mrMaps != nil) ? [self meridianMapForLocation:location] : nil;
	if (map != nil) {
		CLLocationCoordinate2D location2D = [map gpsWithMapPt:location.point];
		NSLog(@"Meridian: at location: [%.6f, %.6f] @ level %d", location2D.latitude, location2D.longitude, map.level);
	}
	else {
		NSLog(@"Meridian: did update location, map not loaded yet");
	}
	

	_mrLocationError = nil;
	_mrLocation = location;
	_mrLocationTimeoutsCount = 0;

	[self setupMeridianTimeoutTimer];
	
	// Ignore the first location update as it is often fake (last remembered location).
	_mrLocationUpdatesCount++;
	if (1 < _mrLocationUpdatesCount) {
		[self notifyMeridianLocationUpdate];
	}
}

#pragma mark MRLocationManagerDelegate / CLLocationManagerDelegate

- (void)locationManager:(id)manager didFailWithError:(NSError *)error {
	if ([manager isKindOfClass:[MRLocationManager class]]) {
		NSLog(@"Meridian: Failed to retrieve location: %@", error.localizedDescription);
		_mrLocation = nil;
		_mrLocationError = error;
		_mrLocationTimeoutsCount = 0;
		[self notifyLocationFail];
		
		[self restartMeridian];
	}
	else if ([manager isKindOfClass:[CLLocationManager class]]) {
		NSLog(@"CoreLocation: Failed to retrieve location: %@", error.localizedDescription);
		_clLocation = nil;
		_clLocationError = error;
		[self notifyLocationFail];
	}
}

#pragma mark Debug Status

#pragma mark MPPositionProvider


- (BOOL)preferAlwaysLocationPermission {
	return _mpPositionProviderPreferAlwaysLocationPermission;
}

- (void)setPreferAlwaysLocationPermission:(BOOL)preferAlwaysLocationPermission {
	_mpPositionProviderPreferAlwaysLocationPermission = preferAlwaysLocationPermission;
}


- (BOOL)locationServicesActive {
	return _mpPositionProviderLocationServicesActive;
}

- (void)setLocationServicesActive:(BOOL)locationServicesActive {
	_mpPositionProviderLocationServicesActive = locationServicesActive;
}

- (void)requestLocationPermissions {
	if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
		[_clLocationManager requestWhenInUseAuthorization];
	}
}

- (void)updateLocationPermissionStatus {
	_mpPositionProviderLocationServicesActive = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
}

- (void)startPositioning:(nullable NSString*)arg {
	[self startMonitor];
}

- (void)stopPositioning:(nullable NSString*)arg {
	[self stopMonitor];
}

- (void)startPositioningAfter:(int)millis arg:(nullable NSString*)arg {
	[NSTimer scheduledTimerWithTimeInterval:(millis / 1000.0) repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self startPositioning:arg];
	}];
}

- (BOOL)isRunning {
	return _isRunning;
}

- (id<MPPositionProviderDelegate>) delegate {
	return _mpPositionProviderDelegate;
}

- (void)setDelegate:(id<MPPositionProviderDelegate>) delegate {
	_mpPositionProviderDelegate = delegate;
}

- (MPPositionResult*)latestPositionResult {
	return _mpPositionResult;
}

- (void)setLatestPositionResult:(MPPositionResult*)latestPositionResult {
	_mpPositionResult = latestPositionResult;
}

- (MPPositionProviderType)providerType {
	return _mpPositionProviderType;
}

- (void)setProviderType:(MPPositionProviderType)providerType {
	_mpPositionProviderType = providerType;
}

#pragma mark GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
}

#pragma mark MPMapControlDelegate

- (void)floorDidChange:(NSNumber*)floor {
	NSLog(@"Maps Indoors: floorDidChange: %d", floor.intValue);
}

@end

