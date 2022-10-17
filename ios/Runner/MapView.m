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
#import "CLLocationCoordinate2D+InaUtils.h"
#import "CGGeometry+InaUtils.h"
#import "NSString+InaJson.h"
#import "NSDate+UIUCUtils.h"
#import "NSDictionary+UIUCExplore.h"

#import <GoogleMaps/GoogleMaps.h>

/////////////////////////////////
// MapView

@interface MapView()<GMSMapViewDelegate> {
	int64_t       _mapId;
	NSArray*      _explores;
	NSDictionary* _exploreOptions;
	NSArray*      _displayExplores;
	NSDictionary* _poi;
	NSMutableSet* _markers;
	float         _currentZoom;
	float         _currentDisplayExploresZoom;
	bool          _didFirstLayout;
	bool          _enabled;
}
@property (nonatomic, readonly) GMSMapView*     mapView;
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
		[self addSubview:_mapView];

		_markers = [[NSMutableSet alloc] init];
		_enabled = true;
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
		[self acknowledgePOI];

		GMSCoordinateBounds* bounds = [self buildDisplayExplores];
		GMSCameraUpdate *cameraUpdate = [self cameraUpdateFromBounds:bounds];
		[_mapView moveCamera:cameraUpdate];

		[self applyEnabled];
	}
}

- (void)applyExplores:(NSArray*)explores options:(NSDictionary*)options {
	_explores = explores;
	_exploreOptions = options;
	if (_didFirstLayout) {
		GMSCoordinateBounds* bounds = [self buildDisplayExplores];
		GMSCameraUpdate *cameraUpdate = [self cameraUpdateFromBounds:bounds];
		[_mapView moveCamera:cameraUpdate];
	}
}

- (GMSCoordinateBounds*)buildDisplayExplores {
	if (_didFirstLayout) {
		NSNumber *debugThresoldDistance = [_exploreOptions inaNumberForKey:@"LocationThresoldDistance"];
		double thresoldDistance = (debugThresoldDistance != nil) ? debugThresoldDistance.doubleValue : self.automaticThresoldDistance;
		_displayExplores = [self buildExplores:_explores thresoldDistance:thresoldDistance];
		return [self buildMarkers];
	}
	return nil;
}

- (NSArray*)buildExplores:(NSArray*)rawExplores thresoldDistance:(double)thresoldDistance {
	
	NSMutableArray *mappedExploreGroups = [[NSMutableArray alloc] init];
	
	for (NSDictionary *explore in rawExplores) {
		if ([explore isKindOfClass:[NSDictionary class]]) {
			int exploreFloor = explore.uiucExploreLocationFloor;
			CLLocationCoordinate2D exploreCoord = explore.uiucExploreLocationCoordinate;
			if (CLLocationCoordinate2DIsValid(exploreCoord)) {
			
				bool exploreMapped = false;
				for (NSMutableArray *mappedExpoloreGroup in mappedExploreGroups) {
					for (NSDictionary *mappedExplore in mappedExpoloreGroup) {
						
						double distance = CLLocationCoordinate2DInaDistance(exploreCoord, mappedExplore.uiucExploreLocationCoordinate);
						if ((distance <= thresoldDistance) && (exploreFloor == mappedExplore.uiucExploreLocationFloor)) {
							[mappedExpoloreGroup addObject:explore];
							exploreMapped = true;
							break;
						}
					}
					if (exploreMapped) {
						break;
					}
				}
				
				if (!exploreMapped) {
					NSMutableArray *mappedExpoloreGroup = [[NSMutableArray alloc] initWithObjects:explore, nil];
					[mappedExploreGroups addObject:mappedExpoloreGroup];
				}
			}
		}
	}
	
	NSMutableArray *resultExplores = [[NSMutableArray alloc] init];
	for (NSMutableArray *mappedExpoloreGroup in mappedExploreGroups) {
		NSDictionary *anExplore = mappedExpoloreGroup.firstObject;
		if (mappedExpoloreGroup.count == 1) {
			[resultExplores addObject:anExplore];
		}
		else {
			[resultExplores addObject:[NSDictionary uiucExploreFromGroup:mappedExpoloreGroup]];
		}
	}

	return resultExplores;
}

- (double)automaticThresoldDistance {
	if (kThresoldOrigin1Zoom <= _mapView.camera.zoom) {
		return kThresoldOrigin1Distance;
	}
	else {
		return kThresoldOrigin1Distance + (kThresoldOrigin1Zoom - _mapView.camera.zoom) / (kThresoldOrigin1Zoom - kThresoldOrigin2Zoom) * (kThresoldOrigin2Distance - kThresoldOrigin1Distance);
	}
}

- (GMSCameraUpdate*)cameraUpdateFromBounds:(GMSCoordinateBounds*)bounds {
		if ((bounds == nil) || !bounds.isValid) {
			return nil;
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

- (void)applyPOI:(NSDictionary*)poi {
	_poi = poi;
	
	if (_didFirstLayout) {
		[self acknowledgePOI];
	}
}

- (void)acknowledgePOI {
	if ((_poi != nil) && _didFirstLayout) {
		NSNumber *latitude = [_poi inaNumberForKey:@"latitude"];
		NSNumber *longitude = [_poi inaNumberForKey:@"longitude"];
		CLLocationCoordinate2D location = ((latitude != nil) && (longitude != nil) && ((longitude.doubleValue != 0.0) || (longitude.doubleValue != 0.0))) ?
			CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue) : kInitialCameraLocation;
		int zoom = [_poi inaIntForKey:@"zoom" defaults:kInitialCameraZoom];

		GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.latitude longitude:location.longitude zoom:(_currentZoom = zoom)];
		GMSCameraUpdate *update = [GMSCameraUpdate setCamera:camera];
		[_mapView moveCamera:update];
		_poi = nil;
	}
}

#pragma mark Display

- (GMSCoordinateBounds*)buildMarkers {

	for (GMSMarker *marker in _markers) {
		marker.map = nil;
	}
	[_markers removeAllObjects];

	GMSCoordinateBounds *bounds = nil;
	for (NSDictionary *explore in _displayExplores) {
		if ([explore isKindOfClass:[NSDictionary class]]) {
			GMSMarker *marker = [self markerFromExplore: explore];
			if (marker != nil) {
				marker.map = _mapView;
				[_markers addObject:marker];
				
				if (bounds == nil) {
					bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:marker.position coordinate:marker.position];
				}
				else {
					bounds = [bounds includingCoordinate:marker.position];
				}
			}
		}
	}
	return bounds;
}

- (GMSMarker*)markerFromExplore:(NSDictionary*)explore {
	CLLocationCoordinate2D exploreCoordinate = explore.uiucExploreLocationCoordinate;
	if (CLLocationCoordinate2DIsValid(exploreCoordinate)) {

		GMSMarker *marker = [[GMSMarker alloc] init];
		marker.position = CLLocationCoordinate2DMake(exploreCoordinate.latitude, exploreCoordinate.longitude);
		
		NSInteger exploresCount = explore.uiucExplores.count;
		if (1 < exploresCount) {
			marker.icon = [MapMarkerView2 groupMarkerImageWithHexColor:explore.uiucExploreMarkerHexColor count:exploresCount];
			marker.groundAnchor = CGPointMake(0.5, 0.5);
		}
		else {
			marker.icon = [MapMarkerView2 markerImageWithHexColor:explore.uiucExploreMarkerHexColor];
			marker.groundAnchor = CGPointMake(0.5, 1);
		}
		marker.title = explore.uiucExploreTitle;
		marker.snippet = explore.uiucExploreDescription;

		marker.zIndex = 1;
		marker.userData = @{ @"explore" : explore };
		return marker;
	}
	return nil;
}


- (void)updateMarkersDisplayMode {

	for (GMSMarker *marker in _markers) {
		MapMarkerView *iconView = [marker.iconView isKindOfClass:[MapMarkerView class]] ? ((MapMarkerView*)marker.iconView) : nil;
		if (iconView != nil) {
			iconView.displayMode = self.markerDisplayMode;
		}
	}
}

- (MapMarkerDisplayMode)markerDisplayMode {
	return (_mapView.camera.zoom < kMarkerThresold1Zoom) ? MapMarkerDisplayMode_Plain : ((_mapView.camera.zoom < kMarkerThresold2Zoom) ? MapMarkerDisplayMode_Title : MapMarkerDisplayMode_Extended);
}

#pragma mark GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
	NSDictionary *arguments = @{
		@"mapId" : @(_mapId)
	};
	[AppDelegate.sharedInstance.flutterMethodChannel invokeMethod:@"map.explore.clear" arguments:arguments.inaJsonString];
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(nonnull GMSMarker *)marker {
	NSDictionary *explore = [marker.userData isKindOfClass:[NSDictionary class]] ? [marker.userData inaDictForKey:@"explore"] : nil;
	id exploreParam = explore.uiucExplores ?: explore;
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

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
	if (_currentZoom != position.zoom) {
		_currentZoom = position.zoom;
		if (kThresoldZoomUpdateStep < fabs(_currentZoom - _currentDisplayExploresZoom)) {
			_currentDisplayExploresZoom = _currentZoom;
			[self buildDisplayExplores];
		}
		else {
			[self updateMarkersDisplayMode];
		}
	}
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
	} else if ([[call method] isEqualToString:@"enable"]) {
		bool enable = [call.arguments isKindOfClass:[NSNumber class]] ? [(NSNumber*)(call.arguments) boolValue] : false;
		[_mapView enable:enable];
	} else if ([[call method] isEqualToString:@"enableMyLocation"]) {
		bool enableMyLocation = [call.arguments isKindOfClass:[NSNumber class]] ? [(NSNumber*)(call.arguments) boolValue] : false;
		[_mapView enableMyLocation:enableMyLocation];
	} else if ([[call method] isEqualToString:@"viewPoi"]) {
		NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
		NSDictionary *targetJsonMap = [parameters inaDictForKey:@"target"];
		[_mapView applyPOI:targetJsonMap];
		result(@(true));
	} else {
		result(FlutterMethodNotImplemented);
	}
}

@end


