////  MapController.m
//  Runner
//
//  Created by Mihail Varbanov on 8/17/22.
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

#import "MapController.h"
#import "AppKeys.h"
#import "MapMarkerView.h"

#import "NSDictionary+InaTypedValue.h"
#import "NSDictionary+UIUCExplore.h"

@interface MapController ()

@end

@implementation MapController

- (instancetype)init {
	if (self = [super init]) {
		self.navigationItem.title = NSLocalizedString(@"Maps", nil);
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
}

#pragma mark GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
}

@end
