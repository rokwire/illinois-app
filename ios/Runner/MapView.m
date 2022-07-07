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
#import <MapsIndoors/MapsIndoors.h>

/////////////////////////////////
// MapView

@interface MapView()<GMSMapViewDelegate, MPMapControlDelegate> {
	int64_t       _mapId;
	NSArray*      _explores;
	NSMutableSet* _markers;
	float         _currentZoom;
	bool          _didFirstLayout;
	bool          _enabled;
}
@property (nonatomic, readonly) GMSMapView*     mapView;
@property (nonatomic, readonly) MPMapControl*   mapControl;
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

		_mapControl = [[MPMapControl alloc] initWithMap:_mapView];
		_mapControl.delegate = self;
		
		_markers = [[NSMutableSet alloc] init];
		_enabled = true;
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame mapId:(int64_t)mapId parameters:(NSDictionary*)parameters {
	if (self = [self initWithFrame:frame]) {
		_mapId = mapId;
		[self enableMyLocation:[parameters inaBoolForKey:@"myLocationEnabled"]];
	}
	return self;
}

- (void)layoutSubviews {
	CGSize contentSize = self.frame.size;
	_mapView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);

	if (!_didFirstLayout) {
		_didFirstLayout = true;
		[self applyMarkers];
		[self applyEnabled];
	}
}

- (void)applyExplores:(NSArray*)explores options:(NSDictionary*)options {
	[self buildExplores:explores options:(NSDictionary*)options];
	if (_didFirstLayout) {
		[self applyMarkers];
	}
}

- (void)buildExplores:(NSArray*)rawExplores options:(NSDictionary*)options {
	NSMutableArray *mappedExploreGroups = [[NSMutableArray alloc] init];
	
	double exploreLocationThresoldDistance = (options != nil) ? [options inaDoubleForKey:@"LocationThresoldDistance" defaults:kExploreLocationThresoldDistance] : kExploreLocationThresoldDistance;
	
	for (NSDictionary *explore in rawExplores) {
		if ([explore isKindOfClass:[NSDictionary class]]) {
			int exploreFloor = explore.uiucExploreLocationFloor;
			CLLocationCoordinate2D exploreCoord = explore.uiucExploreLocationCoordinate;
			if (CLLocationCoordinate2DIsValid(exploreCoord)) {
			
				bool exploreMapped = false;
				for (NSMutableArray *mappedExpoloreGroup in mappedExploreGroups) {
					for (NSDictionary *mappedExplore in mappedExpoloreGroup) {
						
						double distance = CLLocationCoordinate2DInaDistance(exploreCoord, mappedExplore.uiucExploreLocationCoordinate);
						if ((distance < exploreLocationThresoldDistance) && (exploreFloor == mappedExplore.uiucExploreLocationFloor)) {
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

	_explores = resultExplores;
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

#pragma mark Display

- (void)applyMarkers {

	for (GMSMarker *marker in _markers) {
		marker.map = nil;
	}
	[_markers removeAllObjects];

	GMSCoordinateBounds *bounds = nil;

	for (NSDictionary *explore in _explores) {
		if ([explore isKindOfClass:[NSDictionary class]]) {
			NSDictionary *exploreLocation = [explore inaDictForKey:@"location"];
			if (exploreLocation != nil) {
				CLLocationDegrees latitude = [exploreLocation inaDoubleForKey:@"latitude"];
				CLLocationDegrees longitude = [exploreLocation inaDoubleForKey:@"longitude"];

				GMSMarker *marker = [[GMSMarker alloc] init];
				marker.position = CLLocationCoordinate2DMake(latitude, longitude);

				MapMarkerView *iconView = [MapMarkerView createFromExplore:explore];
				marker.iconView = iconView;
				marker.title = iconView.title;
				marker.snippet = iconView.descr;
				marker.groundAnchor = iconView.anchor;

//				marker.icon = [UIImage imageNamed:(1 < explore.uiucExplores.count) ? @"maps-icon-marker-circle-20" : @"maps-icon-marker-pin-30" ];
//				marker.title = explore.uiucExploreTitle;
//				marker.snippet = explore.uiucExploreDescription;
//				marker.groundAnchor = CGPointMake(0.5, 1);

				marker.zIndex = 1;
				marker.userData = @{ @"explore" : explore };
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

	if ((bounds != nil) && _didFirstLayout) {
		_currentZoom = 0;
		GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
		[_mapView moveCamera:update];
		// idleAtCameraPosition -> updateMarkers
	}
	else {
		[self updateMarkers];
	}
}

- (void)updateMarkers {

	int currentFloor = _mapControl.currentFloor.intValue;
	
	for (GMSMarker *marker in _markers) {
		NSDictionary *explore = nil, *exploreLocation = nil;
		if ([marker.userData isKindOfClass:[NSDictionary class]]) {
			explore = [marker.userData inaDictForKey:@"explore"];
			exploreLocation = [explore inaDictForKey:@"location"];
		}

		MapMarkerView *iconView = [marker.iconView isKindOfClass:[MapMarkerView class]] ? ((MapMarkerView*)marker.iconView) : nil;
		if ((iconView != nil) && (exploreLocation != nil)) {
			iconView.displayMode =  (_mapView.camera.zoom < kMarkerThresold1Zoom) ? MapMarkerDisplayMode_Plain : ((_mapView.camera.zoom < kMarkerThresold2Zoom) ? MapMarkerDisplayMode_Title : MapMarkerDisplayMode_Extended);
		}

		NSNumber *markerFloor = nil;
		if (exploreLocation != nil) {
			markerFloor = [exploreLocation inaNumberForKey:@"floor"];
		}
		
		bool markerVisible = ((markerFloor == nil) || (markerFloor.intValue == currentFloor));

		if (markerVisible && (marker.map == nil)) {
			marker.map = _mapView;
		}
		else if (!markerVisible && (marker.map != nil)) {
			marker.map = nil;
		}
	}

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
		[self updateMarkers];
	}
}

#pragma mark MPDirectionsRendererDelegate

- (void)floorDidChange:(NSNumber*)floor {
	[self updateMarkers];
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
		//TBD: implement
		result(@(true));
	} else {
		result(FlutterMethodNotImplemented);
	}
}

@end


