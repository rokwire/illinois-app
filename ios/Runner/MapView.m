//
//  MapView.m
//  Runner
//
//  Created by Mihail Varbanov on 5/21/19.
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

#import "MapView.h"
#import "AppKeys.h"
#import "AppDelegate.h"
#import "MapMarkerView.h"

#import "NSDictionary+InaTypedValue.h"
#import "NSArray+InaTypedValue.h"
#import "CLLocationCoordinate2D+InaUtils.h"
#import "CGGeometry+InaUtils.h"
#import "NSString+InaJson.h"
#import "NSDate+UIUCUtils.h"
#import "NSDictionary+UIUCExplore.h"
#import "InaSymbols.h"

#import <GoogleMaps/GoogleMaps.h>

/////////////////////////////////
// MapView

@interface MapView()<GMSMapViewDelegate> {
	int64_t       _mapId;
	NSArray*      _explores;
	NSDictionary* _exploreOptions;
	NSArray*      _displayExplores;
	NSDictionary* _viewPOI;
	NSDictionary* _markPOI;
	GMSMarker*    _markMarker;
	NSMutableSet* _markers;
	GMSMapStyle*  _mapStyleNoPoi;
	GMSMapStyle*  _mapStyleNoBusStop;
	float         _currentZoom;
	bool          _didFirstLayout;
	bool          _enabled;
	NSOperation*  _buildeExploresOperation;
	NSMutableDictionary<NSString*, UIImage*>* _markersImageCache;
}
@property (nonatomic, readonly) GMSMapView*     mapView;
@property (nonatomic) NSArray*      explores;
@property (nonatomic) NSArray*      displayExplores;
@property (nonatomic) NSMutableSet* markers;
@property (nonatomic) NSOperation*  buildeExploresOperation;
@end

@interface MapViewMarkerData : NSObject
@property (nonatomic) UIImage* image;
@property (nonatomic) CGPoint  anchor;
- (instancetype)initWithImage:image anchor:(CGPoint)anchor;
@end

@implementation MapView

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
	
		GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:kInitialCameraLocation.latitude longitude:kInitialCameraLocation.longitude zoom:(_currentZoom = kInitialCameraZoom)];
		CGRect mapRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		_mapView = [GMSMapView mapWithFrame:mapRect camera:camera];
		_mapView.delegate = self;
		_mapView.settings.compassButton = YES;
		_mapView.accessibilityElementsHidden = NO;
		//_mapView.buildingsEnabled = NO;
		//_mapView.indoorEnabled = NO;
		//_mapView.settings.indoorPicker = NO;
		[self addSubview:_mapView];

		_markers = [[NSMutableSet alloc] init];
		_markersImageCache = [[NSMutableDictionary alloc] init];
		_enabled = true;

	  NSURL *noPoiUrl = [NSBundle.mainBundle URLForResource:@"mapstyle-nopois" withExtension:@"json"];
		_mapStyleNoPoi = [GMSMapStyle styleWithContentsOfFileURL:noPoiUrl	 error:NULL];
		
	  NSURL *noBusStopUrl = [NSBundle.mainBundle URLForResource:@"mapstyle-nostops" withExtension:@"json"];
		_mapStyleNoBusStop = [GMSMapStyle styleWithContentsOfFileURL:noBusStopUrl	 error:NULL];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame mapId:(int64_t)mapId parameters:(NSDictionary*)parameters {
	if (self = [self initWithFrame:frame]) {
		_mapId = mapId;
		[self enableMyLocation:[parameters inaBoolForKey:@"myLocationEnabled" defaults: false]];
	}
	return self;
}

- (void)layoutSubviews {
	CGSize contentSize = self.frame.size;
	_mapView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);

	if (!_didFirstLayout) {
		_didFirstLayout = true;
		[self acknowledgeViewPOI];
		[self acknowledgeMarkPOI];
		[self acknowledgeExplores];
		[self applyEnabled];
	}
}

- (void)applyExplores:(NSArray*)explores options:(NSDictionary*)options {
	_explores = explores;
	_exploreOptions = options;
	if (_didFirstLayout) {
		
		NSNumber *updateOnly = [_exploreOptions inaNumberForKey:@"UpdateOnly"];
		if ([updateOnly boolValue]) {
			[self buildDisplayExplores];
		}
		else {
			[self acknowledgeExplores];
		}
	}
}

- (void)acknowledgeExplores {
	if ((_explores != nil) && _didFirstLayout) {
		GMSCoordinateBounds* bounds = [self boundsOfExplores:_explores];

		double thresoldDistance;
		NSNumber *debugThresoldDistance = [_exploreOptions inaNumberForKey:@"LocationThresoldDistance"];
		if (debugThresoldDistance != nil) {
			thresoldDistance = debugThresoldDistance.doubleValue;
		}
		else {
			GMSCameraPosition *camera = (bounds != nil) ?
				[_mapView cameraForBounds:bounds insets: UIEdgeInsetsMake(50, 50, 50, 50)] :
				[GMSCameraPosition cameraWithTarget:kInitialCameraLocation zoom:kInitialCameraZoom];
			thresoldDistance = [self thresoldDistanceForZoom:camera.zoom];
		}

		[self buildDisplayExploresForThresoldDistance:thresoldDistance];

		GMSCameraUpdate *cameraUpdate = [self cameraUpdateFromBounds:bounds];
		[_mapView moveCamera:cameraUpdate];
	}
}

- (void)buildDisplayExplores {
	if (_didFirstLayout) {
		NSNumber *debugThresoldDistance = [_exploreOptions inaNumberForKey:@"LocationThresoldDistance"];
		double thresoldDistance = (debugThresoldDistance != nil) ? debugThresoldDistance.doubleValue : self.automaticThresoldDistance;
		[self buildDisplayExploresAsyncForThresoldDistance:thresoldDistance];
	}
}

- (void)buildDisplayExploresForThresoldDistance:(double)thresoldDistance {
	NSLog(@"ThresoldDistance: %@", @(thresoldDistance));
	_displayExplores = [self buildExplores:_explores thresoldDistance:thresoldDistance];
	[self applyMarkers:[self buildMarkersFromExplores:_displayExplores]];
}

- (void)buildDisplayExploresAsyncForThresoldDistance:(double)thresoldDistance {
	if (_buildeExploresOperation != nil) {
		[_buildeExploresOperation cancel];
	}
	
	NSBlockOperation* operation = [[NSBlockOperation alloc] init];
	__weak typeof(self) weakSelf = self;
	__weak NSBlockOperation* weakOperation = operation;
	[operation addExecutionBlock:^(){
		NSArray* displayExplores = [weakSelf buildExplores:weakSelf.explores thresoldDistance:thresoldDistance operation:weakOperation];
		if (!weakOperation.cancelled && ![weakSelf.displayExplores isEqualToArray:displayExplores]) {
			NSDictionary<NSNumber*, MapViewMarkerData*>* markerDataMap = [weakSelf buildMarkerDataFromExplores:displayExplores operation:weakOperation];
			if (!weakOperation.cancelled) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if ((weakSelf.buildeExploresOperation != nil) && (weakSelf.buildeExploresOperation == weakOperation)) {
						weakSelf.displayExplores = displayExplores;
						[weakSelf applyMarkers: [weakSelf buildMarkersFromExplores:displayExplores markerDataMap:markerDataMap]];
						weakSelf.buildeExploresOperation = nil;
					}
				});
			}
			else if ((weakSelf.buildeExploresOperation != nil) && (weakSelf.buildeExploresOperation == weakOperation)) {
				weakSelf.buildeExploresOperation = nil;
			}
		}
		else if ((weakSelf.buildeExploresOperation != nil) && (weakSelf.buildeExploresOperation == weakOperation)) {
			weakSelf.buildeExploresOperation = nil;
		}
	}];

	_buildeExploresOperation = operation;
	[AppDelegate.sharedInstance.backgroundOperationQueue addOperation:_buildeExploresOperation];
}


- (NSArray*)buildExplores:(NSArray*)rawExplores thresoldDistance:(double)thresoldDistance {
	return [self buildExplores:rawExplores thresoldDistance:thresoldDistance operation:nil];
}

- (NSArray*)buildExplores:(NSArray*)rawExplores thresoldDistance:(double)thresoldDistance operation:(NSOperation*)operation {
	
	NSMutableArray *mappedExploreGroups = [[NSMutableArray alloc] init];
	
	for (NSDictionary *explore in rawExplores) {
		if (operation.cancelled) {
			break;
		}
		else if ([explore isKindOfClass:[NSDictionary class]]) {
			int exploreFloor = explore.uiucExploreLocationFloor;
			CLLocationCoordinate2D exploreCoord = explore.uiucExploreLocationCoordinate;
			if (CLLocationCoordinate2DIsValid(exploreCoord)) {
			
				bool exploreMapped = false;
				for (NSMutableArray *mappedExpoloreGroup in mappedExploreGroups) {
					for (NSDictionary *mappedExplore in mappedExpoloreGroup) {
						if (operation.cancelled) {
							break;
						}
						double distance = CLLocationCoordinate2DInaDistance(exploreCoord, mappedExplore.uiucExploreLocationCoordinate);
						if ((distance <= thresoldDistance) && (exploreFloor == mappedExplore.uiucExploreLocationFloor)) {
							[mappedExpoloreGroup addObject:explore];
							exploreMapped = true;
							break;
						}
					}
					if (exploreMapped || operation.cancelled) {
						break;
					}
				}
				
				if (!exploreMapped && !operation.cancelled) {
					NSMutableArray *mappedExpoloreGroup = [[NSMutableArray alloc] initWithObjects:explore, nil];
					[mappedExploreGroups addObject:mappedExpoloreGroup];
				}
			}
		}
	}
	
	NSMutableArray *resultExplores = nil;
	if (!operation.cancelled) {
		resultExplores = [[NSMutableArray alloc] init];
		for (NSMutableArray *mappedExpoloreGroup in mappedExploreGroups) {
			if (operation.cancelled) {
				break;
			}
			else {
				NSDictionary *anExplore = mappedExpoloreGroup.firstObject;
				if (mappedExpoloreGroup.count == 1) {
					[resultExplores addObject:anExplore];
				}
				else {
					[resultExplores addObject:[NSDictionary uiucExploreFromGroup:mappedExpoloreGroup]];
				}
			}
		}
	}

	return resultExplores;
}

- (GMSCoordinateBounds*)boundsOfExplores:(NSArray*)rawExplores {
	GMSCoordinateBounds *bounds = nil;
	for (NSDictionary *explore in rawExplores) {
		if ([explore isKindOfClass:[NSDictionary class]]) {
			CLLocationCoordinate2D exploreCoord = explore.uiucExploreLocationCoordinate;
			if (CLLocationCoordinate2DIsValid(exploreCoord)) {
				if (bounds == nil) {
					bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:exploreCoord coordinate:exploreCoord];
				}
				else {
					bounds = [bounds includingCoordinate:exploreCoord];
				}
			}
		}
	}
	return bounds;
}

- (double)automaticThresoldDistance {
	return [self thresoldDistanceForZoom:_mapView.camera.zoom];
}

- (double)thresoldDistanceForZoom:(double)zoom {
	static double const kThresoldDistanceByZoom[] = {
		1000000, 800000, 600000, 200000, 100000, // zoom 0 - 4
		 100000,  80000,  60000,  20000,  10000, // zoom 5 - 9
		   5000,   2000,   1000,    500,    250, // zoom 10 - 14
		    100,     50,      0                  // zoom 15 - 16
		
	};
	NSInteger zoomIndex = round(zoom);
	if ((0 <= zoomIndex) && (zoomIndex < _countof(kThresoldDistanceByZoom))) {
		double zoomDistance = kThresoldDistanceByZoom[zoomIndex];
		double nextZoomDistance = ((zoomIndex + 1) < _countof(kThresoldDistanceByZoom)) ? kThresoldDistanceByZoom[zoomIndex + 1] : 0;
		double thresoldDistance = zoomDistance - (zoom - (double)zoomIndex) * (zoomDistance - nextZoomDistance);
		NSLog(@"thresoldDistanceForZoom: %.2f => %ld", zoom, (NSInteger)floor(thresoldDistance));
		return thresoldDistance;
	}
	return 0;
}


- (GMSCameraUpdate*)cameraUpdateFromBounds:(GMSCoordinateBounds*)bounds {
		if ((bounds == nil) || !bounds.isValid) {
			return [GMSCameraUpdate setTarget:kInitialCameraLocation zoom: kInitialCameraZoom];
		}
		else if (CLLocationCoordinate2DIsEqual(bounds.northEast, bounds.southWest)) {
			return [GMSCameraUpdate setTarget:bounds.northEast zoom: kInitialCameraZoom];
		}
		else {
			return [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
		}
}

- (void)enable:(bool)enable {
	if (_enabled != enable) {
		_enabled = enable;
	
		if (_didFirstLayout) {
			[self applyEnabled];
		}
	}
}

- (void)applyEnabled {
	if (_enabled) {
		if (_mapView.superview == nil) {
			[self addSubview:_mapView];
		}
	}
	else {
		if (_mapView.superview == self) {
			[_mapView removeFromSuperview];
		}
	}
}

- (void)enableMyLocation:(bool)enableMyLocation {
	if (_mapView.myLocationEnabled != enableMyLocation) {
		_mapView.myLocationEnabled = enableMyLocation;
		_mapView.settings.myLocationButton = enableMyLocation;
	}
}

#pragma mark POI

- (void)applyViewPOI:(NSDictionary*)poi {
	_viewPOI = poi;
	
	if (_didFirstLayout) {
		[self acknowledgeViewPOI];
	}
}

- (void)acknowledgeViewPOI {
	if ((_viewPOI != nil) && _didFirstLayout) {
		NSNumber *latitude = [_viewPOI inaNumberForKey:@"latitude"];
		NSNumber *longitude = [_viewPOI inaNumberForKey:@"longitude"];
		CLLocationCoordinate2D location = ((latitude != nil) && (longitude != nil) && ((longitude.doubleValue != 0.0) || (longitude.doubleValue != 0.0))) ?
			CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue) : kInitialCameraLocation;
		int zoom = [_viewPOI inaIntForKey:@"zoom" defaults:kInitialCameraZoom];

		GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.latitude longitude:location.longitude zoom:(_currentZoom = zoom)];
		GMSCameraUpdate *update = [GMSCameraUpdate setCamera:camera];
		[_mapView moveCamera:update];
		_viewPOI = nil;
	}
}

- (void)applyMarkPOI:(NSDictionary*)poi {
	_markPOI = poi;
	
	if (_didFirstLayout) {
		[self acknowledgeMarkPOI];
	}
}

- (void)acknowledgeMarkPOI {
	if (_didFirstLayout) {
		if (_markPOI != nil) {
			GMSMarker *marker = [self markerFromExplore:_markPOI markerData:nil];
			if (marker != nil) {
				_markMarker.map = nil;
				_markMarker = marker;
				_markMarker.map = _mapView;
			}
		}
		else {
			_markMarker.map = nil;
			_markMarker = nil;
		}
	}
}

#pragma mark Display

//_markersImageCache

- (NSDictionary<NSNumber*, MapViewMarkerData*>*)buildMarkerDataFromExplores:(NSArray*)explores operation:(NSOperation*)operation {
	NSMutableDictionary<NSNumber*, MapViewMarkerData*> *markerDataMap = [[NSMutableDictionary alloc] initWithCapacity:explores.count];
	for (NSInteger index = 0; index < explores.count; index++) {
		if (operation.cancelled) {
			break;
		}
		else {
			NSDictionary *explore = [explores inaDictAtIndex:index];
			MapViewMarkerData *markerData = [self markerDataFromExplore:explore];
			if (markerData != nil) {
				[markerDataMap setObject:markerData forKey:@(index)];
			}
		}
	}
	return operation.cancelled ? nil : markerDataMap;
}

- (NSArray<GMSMarker*>*)buildMarkersFromExplores:(NSArray*)explores {
	return [self buildMarkersFromExplores:explores markerDataMap:nil];
}

- (NSArray<GMSMarker*>*)buildMarkersFromExplores:(NSArray*)explores markerDataMap:(NSDictionary<NSNumber*, MapViewMarkerData*>*) markerDataMap {

	NSMutableArray<GMSMarker*> *markers = [[NSMutableArray alloc] initWithCapacity:explores.count];
	for (NSInteger index = 0; index < explores.count; index++) {
		NSDictionary *explore = [explores inaDictAtIndex:index];
		MapViewMarkerData *markerData = [markerDataMap objectForKey:@(index)];
		GMSMarker *marker = [self markerFromExplore:explore markerData:markerData];
		if (marker != nil) {
			[markers addObject:marker];
		}
	}
	return markers;
}

- (void)applyMarkers:(NSArray*)markers {

	for (GMSMarker *marker in _markers) {
		marker.map = nil;
	}
	[_markers removeAllObjects];
	
	MapMarkerDisplayMode displayMode = self.markerDisplayMode;
	bool showMarkerPopups = (_exploreOptions != nil) ? [_exploreOptions inaBoolForKey:@"ShowMarkerPopus" defaults:true] : true;
	for (GMSMarker *marker in markers) {
		//NSDictionary *explore = [marker.userData isKindOfClass:[NSDictionary class]] ? [marker.userData inaDictForKey:@"explore"] : nil;
		if (showMarkerPopups && (MapMarkerDisplayMode_Plain < displayMode) && [_mapView.projection containsCoordinate:marker.position]) {
			MapMarkerView2 *markerView = [[MapMarkerView2 alloc] initWithIcon:marker.icon iconAnchor:marker.groundAnchor title:marker.title descr:marker.snippet displayMode:displayMode];
			marker.iconView = markerView;
			marker.groundAnchor = markerView.anchor;
		}

		marker.map = _mapView;
		[_markers addObject:marker];
	}
}

- (MapViewMarkerData*)markerDataFromExplore:(NSDictionary*)explore {
		UIImage *markerIcon;
		CGPoint markerAnchor;
		if (explore != nil) {
			NSInteger exploresCount = explore.uiucExplores.count;
			if (1 < exploresCount) {
				markerIcon = [MapMarkerView2 groupMarkerImageWithHexColor:explore.uiucExploreMarkerHexColor count:exploresCount imageCache:_markersImageCache];
				markerAnchor = CGPointMake(0.5, 0.5);
			}
			else if (explore.uiucExploreType == UIUCExploreType_MTDStop) {
				markerIcon = [UIImage imageNamed:@"maps-icon-marker-bus"];
				markerAnchor = CGPointMake(0.5, 0.5);
			}
			else {
				markerIcon = [MapMarkerView2 markerImageWithHexColor:explore.uiucExploreMarkerHexColor];
				markerAnchor = CGPointMake(0.5, 1);
			}
			return [[MapViewMarkerData alloc] initWithImage:markerIcon anchor:markerAnchor];
		}
		return nil;
}

- (GMSMarker*)markerFromExplore:(NSDictionary*)explore markerData:(MapViewMarkerData*)markerData {
	CLLocationCoordinate2D exploreCoordinate = (explore != nil) ? explore.uiucExploreLocationCoordinate : kCLLocationCoordinate2DInvalid;
	if (CLLocationCoordinate2DIsValid(exploreCoordinate)) {

		if (markerData == nil) {
			markerData = [self markerDataFromExplore:explore];
		}

		GMSMarker *marker = [[GMSMarker alloc] init];
		marker.position = CLLocationCoordinate2DMake(exploreCoordinate.latitude, exploreCoordinate.longitude);

		marker.icon = markerData.image;
		marker.groundAnchor = markerData.anchor;
		marker.title = explore.uiucExploreTitle;
		marker.snippet = explore.uiucExploreDescription;

		marker.zIndex = 1;
		marker.userData = @{ @"explore" : explore };
		return marker;
	}
	return nil;
}


- (void)updateMarkersDisplayMode {

	bool showMarkerPopups = (_exploreOptions != nil) ? [_exploreOptions inaBoolForKey:@"ShowMarkerPopus" defaults:true] : true;
	if (showMarkerPopups) {
		MapMarkerDisplayMode displayMode = self.markerDisplayMode;
		for (GMSMarker *marker in _markers) {
			//NSDictionary *explore = [marker.userData isKindOfClass:[NSDictionary class]] ? [marker.userData inaDictForKey:@"explore"] : nil;
			BOOL markerVisible = [_mapView.projection containsCoordinate:marker.position];
			MapMarkerView2 *markerView = [marker.iconView isKindOfClass:[MapMarkerView2 class]] ? ((MapMarkerView2*)marker.iconView) : nil;
			if ((MapMarkerDisplayMode_Plain < displayMode) && markerVisible && (markerView == nil)) {
				markerView = [[MapMarkerView2 alloc] initWithIcon:marker.icon iconAnchor:marker.groundAnchor title:marker.title descr:marker.snippet displayMode:displayMode];
				marker.iconView = markerView;
				marker.groundAnchor = markerView.anchor;
			}
			else if (((displayMode == MapMarkerDisplayMode_Plain) || !markerVisible) && (markerView != nil)) {
				marker.groundAnchor = markerView.iconAnchor;
				marker.icon = nil;
			}
			else if (markerView != nil) {
				markerView.displayMode = displayMode;
			}
		}
	}
}

- (MapMarkerDisplayMode)markerDisplayMode {
	return (_mapView.camera.zoom < kMarker2Thresold1Zoom) ? MapMarkerDisplayMode_Plain : ((_mapView.camera.zoom < kMarker2Thresold2Zoom) ? MapMarkerDisplayMode_Title : MapMarkerDisplayMode_Extended);
}

- (void)updateMapStyle {
	GMSMapStyle *mapStyle = _mapView.mapStyle;

	if ([_exploreOptions inaBoolForKey:@"HideBuildingLabels"]) {
		mapStyle = (kNoPoiThresoldZoom <= _mapView.camera.zoom) ? _mapStyleNoPoi : nil;
	}
	else if ([_exploreOptions inaBoolForKey:@"HideBusStopPOIs"]) {
		mapStyle = _mapStyleNoBusStop;
	}

	if (_mapView.mapStyle != mapStyle) {
		_mapView.mapStyle = mapStyle;
	}
}

#pragma mark GMSMapViewDelegate

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(nonnull GMSMarker *)marker {
	NSDictionary *explore = [marker.userData isKindOfClass:[NSDictionary class]] ? [marker.userData inaDictForKey:@"explore"] : nil;
	id exploreParam = explore.uiucExplores ?: explore;
	NSLog(@"didTapMarker: %@", [exploreParam isKindOfClass:[NSArray class]] ?
		[NSString stringWithFormat:@"%@ Explores", @([exploreParam count])] :
		([exploreParam isKindOfClass:[NSDictionary class]] ? [exploreParam uiucExploreTitle] : @"????"));
	if (exploreParam != nil) {
		NSDictionary *arguments = @{
			@"mapId" : @(_mapId),
			@"explore" : exploreParam
		};
		[AppDelegate.sharedInstance.flutterMethodChannel invokeMethod:@"map.explore.select" arguments:arguments.inaJsonString];
		return TRUE; // do nothing
	}
	else {
		return FALSE; // do default behavior
	}
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
	NSLog(@"didTapAtCoordinate: [%.6f, %.6f]", coordinate.latitude, coordinate.longitude);
	NSDictionary *arguments = @{
		@"mapId" : @(_mapId),
		@"location": @{
			@"latitude" : @(coordinate.latitude),
			@"longitude" : @(coordinate.longitude),
		}
	};
	[AppDelegate.sharedInstance.flutterMethodChannel invokeMethod:@"map.location.select" arguments:arguments.inaJsonString];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
	NSLog(@"GMSMapViewZoom: %@", @(position.zoom));
	
	if (kThresoldZoomUpdateStep < fabs(_currentZoom - position.zoom)) {
		_currentZoom = position.zoom;
		[self buildDisplayExplores];
	}
	else {
		[self updateMarkersDisplayMode];
	}
	[self updateMapStyle];
}

- (void)mapView:(GMSMapView *)mapView didTapPOIWithPlaceID:(NSString *)placeID name:(NSString *)name location:(CLLocationCoordinate2D)location {
	NSLog(@"didTapPOIWithPlaceID: %@ name: %@ location: [%.6f, %.6f]", placeID, name, location.latitude, location.longitude);
		
	NSDictionary *arguments = @{
		@"mapId" : @(_mapId),
		@"poi" : @{
			@"placeId" : placeID ?: [NSNull null],
			@"name" : name ?: [NSNull null],
			@"location": @{
				@"latitude" : @(location.latitude),
				@"longitude" : @(location.longitude),
			}
		}
	};
	[AppDelegate.sharedInstance.flutterMethodChannel invokeMethod:@"map.poi.select" arguments:arguments.inaJsonString];
	
}


@end

/////////////////////////////////
// MapViewFactory

@implementation MapViewFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if (self = [super init]) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
	return [[MapViewController alloc] initWithFrame:frame viewId:viewId args:args binaryMessenger:_messenger];
}

@end

/////////////////////////////////
// MapViewController

@interface MapViewController() {
	int64_t _viewId;
	FlutterMethodChannel* _channel;
	MapView *_mapView;

}
@end

@implementation MapViewController

- (instancetype)initWithFrame:(CGRect)frame viewId:(int64_t)viewId args:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
	if (self = [super init]) {
		_viewId = viewId;

		NSDictionary *parameters = [args isKindOfClass:[NSDictionary class]] ? args : nil;
		_mapView = [[MapView alloc] initWithFrame:frame mapId:viewId parameters:parameters];
		
		NSString* channelName = [NSString stringWithFormat:@"mapview_%lld", (long long)viewId];
		_channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
		__weak __typeof__(self) weakSelf = self;
		[_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
			[weakSelf onMethodCall:call result:result];
		}];
		
	}
	return self;
}

- (UIView*)view {
	return _mapView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
	if ([[call method] isEqualToString:@"placePOIs"]) {
		NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
		NSArray *exploresJsonList = [parameters inaArrayForKey:@"explores"];
		NSDictionary *optionsJsonMap = [parameters inaDictForKey:@"options"];
		[_mapView applyExplores:exploresJsonList options:optionsJsonMap];
		result(@(true));
	}
	else if ([[call method] isEqualToString:@"enable"]) {
		bool enable = [call.arguments isKindOfClass:[NSNumber class]] ? [(NSNumber*)(call.arguments) boolValue] : false;
		[_mapView enable:enable];
	}
	else if ([[call method] isEqualToString:@"enableMyLocation"]) {
		bool enableMyLocation = [call.arguments isKindOfClass:[NSNumber class]] ? [(NSNumber*)(call.arguments) boolValue] : false;
		[_mapView enableMyLocation:enableMyLocation];
	}
	else if ([[call method] isEqualToString:@"viewPOI"]) {
		NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
		NSDictionary *targetJsonMap = [parameters inaDictForKey:@"target"];
		[_mapView applyViewPOI:targetJsonMap];
		result(@(true));
	}
	else if ([[call method] isEqualToString:@"markPOI"]) {
		NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
		NSDictionary *exploreJsonMap = [parameters inaDictForKey:@"explore"];
		[_mapView applyMarkPOI:exploreJsonMap];
		result(@(true));
	}
	else {
		result(FlutterMethodNotImplemented);
	}
}

@end


@implementation MapViewMarkerData

- (instancetype)initWithImage:image anchor:(CGPoint)anchor {
	if (self = [super init]) {
		_image = image;
		_anchor = anchor;
	}
	return self;
}

@end
