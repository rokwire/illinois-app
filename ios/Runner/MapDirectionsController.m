//
//  MapDirectionsController.m
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

#import "MapDirectionsController.h"
#import "AppDelegate.h"
#import "AppKeys.h"
#import "MapMarkerView.h"
#import "Navigation.h"

#import "NSDictionary+UIUCConfig.h"
#import "NSDictionary+InaTypedValue.h"
#import "NSArray+InaTypedValue.h"
#import "NSString+InaJson.h"
#import "NSUserDefaults+InaUtils.h"
#import "UIColor+InaParse.h"
#import "CLLocationCoordinate2D+InaUtils.h"
#import "NSDictionary+UIUCExplore.h"
#import "InaSymbols.h"


typedef NS_ENUM(NSInteger, NavStatus) {
	NavStatus_Unknown,
	NavStatus_Start,
	NavStatus_Progress,
	NavStatus_Finished,
};

typedef struct {
	NSInteger legIndex;
	NSInteger stepIndex;
} NavRouteSegment;


@interface NavRoute(InaUtils)
- (bool)isValidSegment:(NavRouteSegment)segment;
- (NavRouteSegment)findNearestSegmentFromLocation:(CLLocationCoordinate2D)location;
- (NSString*)displayDecription;
@end

static NavRouteSegment NavRouteSegmentMake(NSInteger legIndex, NSInteger stepIndex);
static bool NavRouteSegmentIsEqual(NavRouteSegment segment1, NavRouteSegment segment2);

static const NSString * kTravelModeKey = @"mapDirections.travelMode";

@interface MapDirectionsController(){
	float         									_currentZoom;
}
@property (nonatomic, strong) NSDictionary*         explore;
@property (nonatomic, strong) NSDictionary*         exploreLocation;
@property (nonatomic, strong) NSString*             exploreAddress;
@property (nonatomic)         NSError*              exploreAddressError;

@property (nonatomic, strong) UIActivityIndicatorView*
                                                    activityIndicator;
@property (nonatomic, strong) UILabel*              activityStatus;
@property (nonatomic, strong) UIAlertController*    alertController;

@property (nonatomic, strong) CLLocationManager*    clLocationManager;
@property (nonatomic, strong) CLLocation*           clLocation;
@property (nonatomic, strong) NSError*              clLocationError;

@property (nonatomic, strong) NSArray<NSString*>*   nsTravelModes;
@property (nonatomic, strong) UISegmentedControl*   navTravelModesCtrl;
@property (nonatomic, strong) UIButton*             navRefreshButton;
@property (nonatomic, strong) UIButton*             navAutoUpdateButton;
@property (nonatomic, strong) UIButton*             navPrevButton;
@property (nonatomic, strong) UIButton*             navNextButton;
@property (nonatomic, strong) UILabel*              navStepLabel;
@property (nonatomic, strong) UILabel*              debugStatusLabel;
@property (nonatomic, assign) NavStatus             navStatus;
@property (nonatomic, assign) bool                  navAutoUpdate;
@property (nonatomic, assign) bool                  navDidFirstLocationUpdate;

@property (nonatomic, strong) NavRoute*             navRoute;
@property (nonatomic, strong) NSError*              navRouteError;
@property (nonatomic, assign) NavRouteSegment       navRouteSegment;
@property (nonatomic, strong) GMSPolyline*          gmsRoutePolyline;
@property (nonatomic, strong) GMSCameraPosition*    gmsRouteCameraPosition;
@property (nonatomic, assign) bool                  navRouteLoading;
@property (nonatomic, strong) GMSMarker*            gmsExploreMarker;
@property (nonatomic, strong) GMSPolygon*           gmsExplorePolygone;
@property (nonatomic, strong) GMSMarker*            gmsSegmentStartMarker;
@property (nonatomic, strong) GMSMarker*            gmsSegmentEndMarker;
@property (nonatomic, strong) GMSPolyline*          gmsSegmentPolyline;

@end

/////////////////////////////////
// MapDirectionsController

@implementation MapDirectionsController

- (instancetype)init {
	if (self = [super init]) {
		self.navigationItem.title = NSLocalizedString(@"Directions", nil);
		
		_nsTravelModes = @[ kNavTravelModeWalking, kNavTravelModeBicycling, kNavTravelModeDriving, kNavTravelModeTransit ];

		_clLocationManager = [[CLLocationManager alloc] init];
		_clLocationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
		_clLocationManager.delegate = self;
		
		_navRouteSegment = NavRouteSegmentMake(-1, -1);
	}
	return self;
}

- (instancetype)initWithParameters:(NSDictionary*)parameters completionHandler:(FlutterCompletion)completionHandler {
	if (self = [super initWithParameters:parameters completionHandler:completionHandler]) {
		
		id exploreParam = [self.parameters objectForKey:@"explore"];
		if ([exploreParam isKindOfClass:[NSDictionary class]]) {
			_explore = exploreParam;
		}
		else if ([exploreParam isKindOfClass:[NSArray class]]) {
			_explore = [NSDictionary uiucExploreFromGroup:exploreParam];
		}

//#ifdef DEBUG
//		_explore = @{@"title" : @"Woman Restroom",@"location":@{@"latitude":@(40.1131343), @"longitude":@(-88.2259209), @"floor": @(30), @"building":@"DCL"}};
//		_explore = @{@"title" : @"Mens Restroom",@"location":@{@"latitude":@(40.0964976), @"longitude":@(-88.2364674), @"floor": @(20), @"building":@"State Farm"}};
//#endif

		_exploreLocation = _explore.uiucExploreDestinationLocation;
		_exploreAddress = _explore.uiucExploreAddress;
	}
	return self;
}

- (void)loadView {
	[super loadView];

	self.gmsMapView.myLocationEnabled = true;

	_currentZoom = self.gmsMapView.camera.zoom;

	_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	_activityIndicator.color = [UIColor blackColor];
	[self.view addSubview:_activityIndicator];
	
	_activityStatus = [[UILabel alloc] initWithFrame:CGRectZero];
	_activityStatus.font = [UIFont systemFontOfSize:14];
	_activityStatus.textAlignment = NSTextAlignmentCenter;
	_activityStatus.textColor = [UIColor darkGrayColor];
	[self.view addSubview:_activityStatus];
	
	_navTravelModesCtrl = [[UISegmentedControl alloc] initWithFrame:CGRectZero];
	_navTravelModesCtrl.tintColor = [UIColor inaColorWithHex:@"#606060"];
	[_navTravelModesCtrl addTarget:self action:@selector(didNavTravelMode) forControlEvents:UIControlEventValueChanged];
	NSInteger selectedTravelModeIndex = [self buildTravelModeSegments];
	[_navTravelModesCtrl setSelectedSegmentIndex:selectedTravelModeIndex];
	[self.gmsMapView addSubview:_navTravelModesCtrl];

	_navRefreshButton = [[UIButton alloc] initWithFrame:CGRectZero];
	[_navRefreshButton setExclusiveTouch:YES];
	[_navRefreshButton setImage:[UIImage imageNamed:@"button-icon-nav-refresh"] forState:UIControlStateNormal];
	[_navRefreshButton addTarget:self action:@selector(didNavRefresh) forControlEvents:UIControlEventTouchUpInside];
	[self.gmsMapView addSubview:_navRefreshButton];
	
	_navAutoUpdateButton = [[UIButton alloc] initWithFrame:CGRectZero];
	[_navAutoUpdateButton setExclusiveTouch:YES];
	[_navAutoUpdateButton setImage:[UIImage imageNamed:@"button-icon-nav-location"] forState:UIControlStateNormal];
	[_navAutoUpdateButton addTarget:self action:@selector(didNavAutoUpdate) forControlEvents:UIControlEventTouchUpInside];
	[self.gmsMapView addSubview:_navAutoUpdateButton];

	_navPrevButton = [[UIButton alloc] initWithFrame:CGRectZero];
	[_navPrevButton setExclusiveTouch:YES];
	[_navPrevButton setImage:[UIImage imageNamed:@"button-icon-nav-prev"] forState:UIControlStateNormal];
	[_navPrevButton addTarget:self action:@selector(didNavPrev) forControlEvents:UIControlEventTouchUpInside];
	[self.gmsMapView addSubview:_navPrevButton];

	_navNextButton = [[UIButton alloc] initWithFrame:CGRectZero];
	[_navNextButton setExclusiveTouch:YES];
	[_navNextButton setImage:[UIImage imageNamed:@"button-icon-nav-next"] forState:UIControlStateNormal];
	[_navNextButton addTarget:self action:@selector(didNavNext) forControlEvents:UIControlEventTouchUpInside];
	[self.gmsMapView addSubview:_navNextButton];

	_navStepLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	_navStepLabel.font = [UIFont systemFontOfSize:18];
	_navStepLabel.numberOfLines = 2;
	_navStepLabel.textAlignment = NSTextAlignmentCenter;
	_navStepLabel.textColor = [UIColor blackColor];
	_navStepLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.5];
	_navStepLabel.shadowOffset = CGSizeMake(2, 2);
	[self.gmsMapView addSubview:_navStepLabel];

	NSDictionary *options = [self.parameters inaDictForKey:@"options"];
	if ([options inaBoolForKey:@"showDebugLocation"]) {
		_debugStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_debugStatusLabel.font = [UIFont boldSystemFontOfSize:12];
		_debugStatusLabel.textAlignment = NSTextAlignmentCenter;
		_debugStatusLabel.textColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1.0];
		_debugStatusLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.5];
		_debugStatusLabel.shadowOffset = CGSizeMake(2, 2);
		[self.gmsMapView addSubview:_debugStatusLabel];
	}
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
}

- (void)layoutSubViews {
	[super layoutSubViews];

	CGSize contentSize = self.view.frame.size;
	
	CGSize activityIndSize = [_activityIndicator sizeThatFits:contentSize];
	CGFloat activityIndY = contentSize.height / 2 - activityIndSize.height - 8;
	_activityIndicator.frame = CGRectMake((contentSize.width - activityIndSize.width) / 2, activityIndY, activityIndSize.width, activityIndSize.height);
	
	CGFloat activityTxtY = contentSize.height / 2 + 8, activityTxtGutterW = 16, activityTxtH = 16;
	_activityStatus.frame = CGRectMake(activityTxtGutterW, activityTxtY, MAX(contentSize.width - 2 * activityTxtGutterW, 0), activityTxtH);

	CGFloat navBtnSize = 42;
	CGFloat navX = 0, navY, navW = contentSize.width;
	navX += navBtnSize / 2; navW = MAX(navW - navBtnSize, 0);
	
	navY = navBtnSize / 2;
	_navRefreshButton.frame = CGRectMake(navX, navY, navBtnSize, navBtnSize);
	
	CGFloat navAutoUpdateX = navX + 3 * navBtnSize / 2;
	_navAutoUpdateButton.frame = CGRectMake(navAutoUpdateX, navY, navBtnSize, navBtnSize);
	
	CGFloat navTravelModeBtnSize = 36;
	CGSize navTravelModesSize = CGSizeMake(navTravelModeBtnSize * _navTravelModesCtrl.numberOfSegments * 3 / 2, navTravelModeBtnSize);
	_navTravelModesCtrl.frame = CGRectMake(contentSize.width - navTravelModesSize.width - 4, navY + (navBtnSize - navTravelModeBtnSize) / 2, navTravelModesSize.width, navTravelModesSize.height);
	
	navY = contentSize.height - 2 * navBtnSize;
	_navPrevButton.frame = CGRectMake(navX, navY, navBtnSize, navBtnSize);
	_navNextButton.frame = CGRectMake(navX + navW - navBtnSize, navY, navBtnSize, navBtnSize);

	navX += navBtnSize; navW = MAX(navW - 2 * navBtnSize, 0);
	_navStepLabel.frame = CGRectMake(navX, navY - navBtnSize / 2, navW, 2 * navBtnSize);

	if (_debugStatusLabel != nil) {
		CGFloat labelH = 12;
		_debugStatusLabel.frame = CGRectMake(0, contentSize.height - 1 - labelH, contentSize.width, labelH);
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self updateNav];
	[self prepare];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_clLocationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[_clLocationManager stopUpdatingLocation];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	CLLocation* location = [locations lastObject];
	NSLog(@"CoreLocation: at location: [%.6f, %.6f]", location.coordinate.latitude, location.coordinate.longitude);

	_clLocation = location;
	_clLocationError = nil;
	
	if (_clLocation != nil) {
		
		if (!_navDidFirstLocationUpdate) {
			_navDidFirstLocationUpdate = true;
			[self didFirstLocationUpdate];
		}

		if ((_navStatus == NavStatus_Progress) && _navAutoUpdate) {
			[self updateNavByCurrentLocation];
		}
		else {
			[self updateNav];
		}

		if (_debugStatusLabel != nil) {
			_debugStatusLabel.text = [NSString stringWithFormat:@"[%.6f, %.6f]", _clLocation.coordinate.latitude, _clLocation.coordinate.longitude];
		}
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"CoreLocation: error: %@", error.localizedDescription);

	_clLocation = nil;
	_clLocationError = error;
	
	if (error != nil) {
	
		if (!_navDidFirstLocationUpdate) {
			_navDidFirstLocationUpdate = true;
			[self didFirstLocationUpdate];
		}
		else {
			[self updateNav];
		}

		if (_debugStatusLabel != nil) {
			_debugStatusLabel.text = [NSString stringWithFormat:@"{%@}", _clLocationError.localizedDescription];
		}
	}
	
}


#pragma mark Navigation

- (void)prepare {
	if (_exploreLocation != nil) {
		self.gmsMapView.hidden = true;
		[_activityIndicator startAnimating];
		[_activityStatus setText:NSLocalizedString(@"Detecting current location...",nil)];
		[self buildExploreMarker];
	}
	else if (_exploreAddress != nil) {
		self.gmsMapView.hidden = true;
		[_activityIndicator startAnimating];
		[_activityStatus setText:NSLocalizedString(@"Resolving target address ...",nil)];

		__weak typeof(self) weakSelf = self;
		CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
		[geoCoder geocodeAddressString:_exploreAddress completionHandler:^(NSArray<CLPlacemark*>* placemarks, NSError* error) {
			CLPlacemark *placemark = placemarks.firstObject;
			if (placemark.location != nil) {
				weakSelf.exploreLocation = @{
					@"latitude" : @(placemark.location.coordinate.latitude),
					@"longitude" : @(placemark.location.coordinate.longitude),
				};
				[weakSelf buildExploreMarker];
			}
			else {
				weakSelf.exploreAddressError = error ?: [NSError errorWithDomain:@"com.illinois.rokwire" code:1 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to resolve target address.", nil) }];
			}

			if (weakSelf.navDidFirstLocationUpdate) {
				[weakSelf didFirstLocationUpdate];
			}
			else {
				[weakSelf.activityStatus setText:NSLocalizedString(@"Detecting current location...", nil)];
			}
		}];
	}
	else {
		// Simply do nothing
	}
	
	[self buildExplorePolygon];
}

- (void)didFirstLocationUpdate {
	if (_exploreLocation == nil) {
		if (_exploreAddress != nil) {
			if (_exploreAddressError != nil) {
				if (self.gmsMapView.hidden) {
					self.gmsMapView.hidden = false;
					[_activityIndicator stopAnimating];
					[_activityStatus setText:@""];

					[self alertMessage:_exploreAddressError.debugDescription];
				}
			}
			else {
				// Still Loading
			}
		}
		else {
			// Do nothing
			if (self.gmsMapView.hidden) {
				self.gmsMapView.hidden = false;
				[_activityIndicator stopAnimating];
				[_activityStatus setText:@""];
			}
			
			if (_clLocation != nil) {
				// Position camera on user location
				CLLocationCoordinate2D currentLocationCoord = CLLocationCoordinate2DMake(_clLocation.coordinate.latitude, _clLocation.coordinate.longitude);
				GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate setTarget:currentLocationCoord  zoom:kInitialCameraZoom];
				[self.gmsMapView moveCamera:cameraUpdate];
			}
		}
	}
	else if (_clLocation == nil) {
		// Show map and present error message
		if (self.gmsMapView.hidden) {
			self.gmsMapView.hidden = false;
			[_activityIndicator stopAnimating];
			[_activityStatus setText:@""];
			
			// Position camera on explore location
			GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate setTarget:_exploreLocation.uiucLocationCoordinate  zoom:kInitialCameraZoom];
			[self.gmsMapView moveCamera:cameraUpdate];
			
			[self updateNav];

			// Alert error
			NSString *message = nil;
			if (0 < self.clLocationError.localizedDescription.length) {
				message = self.clLocationError.localizedDescription;
			}
			else {
				message = NSLocalizedString(@"Failed to detect current location.", nil);
			}
			[self alertMessage:message];
		}
	}
	else {
		// Build route
		if ((_navRouteLoading == false) && (_navRoute == nil) && (_navRouteError == nil)) {
			[self buildRoute];
		}
	}
}

- (void)buildRoute {
	NSString *travelMode = ((0 <= _navTravelModesCtrl.selectedSegmentIndex) && (_navTravelModesCtrl.selectedSegmentIndex < _nsTravelModes.count)) ? [_nsTravelModes objectAtIndex:_navTravelModesCtrl.selectedSegmentIndex] : _nsTravelModes.firstObject;
	[self buildRouteWithTravelMode:travelMode];
}

- (void)buildRouteWithTravelMode:(NSString*)travelMode {
	[_activityStatus setText:NSLocalizedString(@"Looking for route...", nil)];
	[_activityIndicator startAnimating];

	CLLocationCoordinate2D orgLocation = _clLocation.coordinate;
	CLLocationCoordinate2D dstLocation = _exploreLocation.uiucLocationCoordinate;
	
	NSLog(@"Lookup Route: [%.6f, %.6f] -> [%.6f, %.6f]", orgLocation.latitude, orgLocation.longitude, dstLocation.latitude, dstLocation.longitude);

	_navRouteLoading = true;
	__weak typeof(self) weakSelf = self;
	[Navigation findRouteFromOrigin:orgLocation destination:dstLocation travelMode:travelMode completionHandler:^(NavRoute *route, NSError *error) {
		weakSelf.navRouteLoading = false;
		weakSelf.navRoute = route;
		weakSelf.navRouteError = error;
		[weakSelf didBuildRoute];
	}];
}

- (void)didBuildRoute {
	
	self.gmsMapView.hidden = false;
	[_activityIndicator stopAnimating];
	[_activityStatus setText:@""];

	if (_navRoute != nil) {
		[self buildRoutePolyline];
		_gmsSegmentStartMarker = [self buildSegmentMarker];
		_gmsSegmentEndMarker = [self buildSegmentMarker];
		_gmsSegmentPolyline = [self buildSegmentPolyline];
		_navRouteSegment = NavRouteSegmentMake(-1, -1);
		_gmsRouteCameraPosition = self.gmsMapView.camera;
		_navStatus = NavStatus_Start;
	}
	[self updateNav];

	GMSCoordinateBounds *bounds = [self buildRouteBounds];
	GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
	[self.gmsMapView moveCamera:cameraUpdate];

	if (_navRoute == nil) {
		NSString *message = nil;
		if (0 < _navRouteError.localizedDescription.length) {
			message = _navRouteError.localizedDescription;
		}
		else {
			message = NSLocalizedString(@"Failed to find route.", nil);
		}

		[self alertMessage:message];
	}
}

- (void)buildExploreMarker {
	if (_exploreLocation != nil) {
		_gmsExploreMarker = [[GMSMarker alloc] init];
		_gmsExploreMarker.position = _exploreLocation.uiucLocationCoordinate;

		MapMarkerView *iconView = [MapMarkerView createFromExplore:_explore displayMode:self.markerDisplayMode];
		_gmsExploreMarker.iconView = iconView;
		_gmsExploreMarker.title = iconView.title;
		_gmsExploreMarker.snippet = iconView.descr;
		_gmsExploreMarker.groundAnchor = iconView.anchor;
		_gmsExploreMarker.zIndex = 10;
		_gmsExploreMarker.userData = @{ @"explore" : _explore };
		_gmsExploreMarker.map = self.gmsMapView;
		[self updateExploreMarker];
	}
}

- (void)updateExploreMarker {
	MapMarkerView *iconView = [_gmsExploreMarker.iconView isKindOfClass:[MapMarkerView class]] ? ((MapMarkerView*)_gmsExploreMarker.iconView) : nil;
	if (iconView != nil) {
		iconView.displayMode = self.markerDisplayMode;
	}
}

- (MapMarkerDisplayMode)markerDisplayMode {
	return (self.gmsMapView.camera.zoom < kMarkerThresold1Zoom) ? MapMarkerDisplayMode_Plain : ((self.gmsMapView.camera.zoom < kMarkerThresold2Zoom) ? MapMarkerDisplayMode_Title : MapMarkerDisplayMode_Extended);
}

- (void)buildExplorePolygon {
	NSArray *explorePolygon = _explore.uiucExplorePolygon;
	if (0 < explorePolygon.count) {
		GMSMutablePath *path = [[GMSMutablePath alloc] init];
		for (NSDictionary *point in explorePolygon) {
			if ([point isKindOfClass:[NSDictionary class]]) {
				[path addCoordinate:point.uiucLocationCoordinate];
			}
		}
		if (0 < path.count) {
			_gmsExplorePolygone = [[GMSPolygon alloc] init];
			_gmsExplorePolygone.path = path;
			_gmsExplorePolygone.title = _explore.uiucExploreTitle;
			_gmsExplorePolygone.fillColor = [UIColor colorWithWhite:0.0 alpha:0.03];
			_gmsExplorePolygone.strokeColor = [UIColor inaColorWithHex:_explore.uiucExploreMarkerHexColor];
			_gmsExplorePolygone.strokeWidth = 2;
			_gmsExplorePolygone.zIndex = 1;
			_gmsExplorePolygone.userData = @{ @"explore" : _explore };
			_gmsExplorePolygone.map = self.gmsMapView;
		}
	}
}

- (void)buildRoutePolyline {
	GMSMutablePath *routePath = [[GMSMutablePath alloc] init];
	for (NavRouteLeg *leg in _navRoute.legs) {
		for (NavRouteStep *step in leg.steps) {
			GMSPath *gmStepPath = [GMSPath pathFromEncodedPath:step.polyline.points];
			for (NSInteger index = 0; index < gmStepPath.count; index++) {
				[routePath addCoordinate:[gmStepPath coordinateAtIndex:index]];
			}
		}
	}
	
	_gmsRoutePolyline = [GMSPolyline polylineWithPath:routePath];
	//_gmsRoutePolyline.strokeColor = [UIColor inaColorWithHex:@"e84a27"];
	_gmsRoutePolyline.map = self.gmsMapView;
}

- (void)clearRoutePolyline {

}

- (GMSCoordinateBounds*)buildRouteBounds {
	GMSMutablePath *path = [[GMSMutablePath alloc] init];
	[path addCoordinate:_clLocation.coordinate];
	[path addCoordinate:_exploreLocation.uiucLocationCoordinate]; // explore location

	if (_navRoute.bounds != nil) {
		[path addCoordinate:CLLocationCoordinate2DMake(_navRoute.bounds.northeast.coordinate.latitude, _navRoute.bounds.northeast.coordinate.longitude)];
		[path addCoordinate:CLLocationCoordinate2DMake(_navRoute.bounds.southwest.coordinate.latitude, _navRoute.bounds.southwest.coordinate.longitude)];
	}

	NSArray *explorePolygon = _explore.uiucExplorePolygon;
	if (0 < explorePolygon.count) {
		for (NSDictionary *point in explorePolygon) {
			if ([point isKindOfClass:[NSDictionary class]]) {
				[path addCoordinate:point.uiucLocationCoordinate];
			}
		}
	}

	return [[GMSCoordinateBounds alloc] initWithPath:path];
}

- (GMSMarker*)buildSegmentMarker {
	GMSMarker *segmentMarker = [[GMSMarker alloc] init];
	segmentMarker.icon = [UIImage imageNamed:@"maps-icon-marker-origin"];
	segmentMarker.groundAnchor = CGPointMake(0.5, 0.5);
	segmentMarker.zIndex = 9;
	//segmentMarker.position = ...;
	//segmentMarker.map = self.gmsMapView;
	return segmentMarker;
}

- (GMSPolyline*)buildSegmentPolyline {
	GMSPolyline *segmentPolyline = [[GMSPolyline alloc] init];
	segmentPolyline.strokeColor = [UIColor inaColorWithHex:@"3474d6"];
	segmentPolyline.strokeWidth = 5;
	segmentPolyline.zIndex = 8;
	//segmentPolyline.map = self.gmsMapView;
	return segmentPolyline;
}

#pragma mark Navigation

- (void)updateNav {
	bool errorState = ((_clLocationError != nil) && (_clLocation == nil));
	
	_navRefreshButton.hidden = errorState;
	_navRefreshButton.enabled = (_navRouteLoading != true);

	_navTravelModesCtrl.hidden = ((_navStatus != NavStatus_Unknown) && (_navStatus != NavStatus_Start)) || errorState;
	_navTravelModesCtrl.enabled = (_navRouteLoading != true);

	_navAutoUpdateButton.hidden = (_navStatus != NavStatus_Progress) || _navAutoUpdate || errorState;
	_navPrevButton.hidden = _navNextButton.hidden = _navStepLabel.hidden = (_navStatus == NavStatus_Unknown);

	if (_navStatus == NavStatus_Start) {
		NSString *routeDescription = _navRoute.displayDecription;
		[self setStepHtml:[NSString stringWithFormat:@"<b>%@</b>%@",
			NSLocalizedString(@"START", nil),
			(0 < routeDescription.length) ? [NSString stringWithFormat:@"<br>(%@)", routeDescription] : @""
		]];

		_navPrevButton.enabled = false;
		_navNextButton.enabled = true;
	}
	else if (_navStatus == NavStatus_Progress) {
		NSInteger legIndex = _navRouteSegment.legIndex;
		NavRouteLeg *leg = ((0 <= legIndex) && (legIndex < _navRoute.legs.count)) ? [_navRoute.legs objectAtIndex:legIndex] : nil;
		
		NSInteger stepIndex = _navRouteSegment.stepIndex;
		NavRouteStep *step = ((0 <= stepIndex) && (stepIndex < leg.steps.count)) ? [leg.steps objectAtIndex:stepIndex] : nil;

		if (0 < step.instructionsHtml.length) {
			[self setStepHtml:step.instructionsHtml];
		}
		else if (0 < step.maneuver.length) {
			_navStepLabel.text = step.maneuver;
		}
		else if ((0 < step.distance.text.length) || (0 < step.duration.text.length)) {
			_navStepLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ / %@", nil), step.distance.text, step.duration.text];
		}
		else {
			_navStepLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Leg %d / Step %d", nil), (int)legIndex + 1, (int)stepIndex + 1];
		}

		_navPrevButton.enabled = _navNextButton.enabled = true;
		
		NSLog(@"At Route Step (%d:%d): [%.6f, %.6f] -> [%.6f, %.6f]", (int)legIndex, (int)stepIndex, step.startLocation.coordinate.latitude, step.startLocation.coordinate.longitude, step.endLocation.coordinate.latitude, step.endLocation.coordinate.longitude);
	}
	else if (_navStatus == NavStatus_Finished) {
		[self setStepHtml:[NSString stringWithFormat:@"<b>%@</b>", NSLocalizedString(@"FINISH", nil)]];

		_navPrevButton.enabled = true;
		_navNextButton.enabled = false;
	}
}

- (void)updateNavAutoUpdate {
	NavRouteSegment segment = [self findNearestRouteSegmentByCurrentLocation];
	_navAutoUpdate = [_navRoute isValidSegment:segment] && (_navRouteSegment.legIndex == segment.legIndex) && (_navRouteSegment.stepIndex == segment.stepIndex);
}

- (void)didNavPrev {
	if (_navStatus == NavStatus_Start) {
	}
	else if (_navStatus == NavStatus_Progress) {
		NSInteger legIndex = _navRouteSegment.legIndex;
		NSInteger stepIndex = _navRouteSegment.stepIndex;
		
		if (0 < stepIndex) {
			[self applyNavSegment:NavRouteSegmentMake(legIndex, --stepIndex)];
		}
		else if (0 < legIndex) {
			NavRouteLeg *leg = (legIndex < _navRoute.legs.count) ? [_navRoute.legs objectAtIndex:legIndex] : nil;
			[self applyNavSegment:NavRouteSegmentMake(--legIndex, leg.steps.count - 1)];
		}
		else {
			_navStatus = NavStatus_Start;
			[self applyNavSegment:NavRouteSegmentMake(-1, -1)];
		}
	}
	else if (_navStatus == NavStatus_Finished) {
		_navStatus = NavStatus_Progress;
		[self applyNavSegment:NavRouteSegmentMake(_navRoute.legs.count - 1, _navRoute.legs.lastObject.steps.count - 1)];
	}
	
	[self updateNavAutoUpdate];
	[self updateNav];
}

- (void)didNavNext {
	if (_navStatus == NavStatus_Start) {
		_navStatus = NavStatus_Progress;
		[self applyNavSegment:NavRouteSegmentMake(0, 0)];
		[self notifyRouteStart];
	}
	else if (_navStatus == NavStatus_Progress) {
		NSInteger legIndex = _navRouteSegment.legIndex;
		NSInteger stepIndex = _navRouteSegment.stepIndex;

		NavRouteLeg *leg = ((0 <= legIndex) && (legIndex < _navRoute.legs.count)) ? [_navRoute.legs objectAtIndex:legIndex] : nil;
		
		if ((stepIndex + 1) < leg.steps.count) {
			[self applyNavSegment:NavRouteSegmentMake(legIndex, ++stepIndex)];
		}
		else if ((legIndex + 1) < _navRoute.legs.count) {
			[self applyNavSegment:NavRouteSegmentMake(++legIndex, 0)];
		}
		else {
			_navStatus = NavStatus_Finished;
			[self applyNavSegment:NavRouteSegmentMake(-1, -1)];
			[self notifyRouteFinish];
		}
	}
	else if (_navStatus == NavStatus_Finished) {
	}

	[self updateNavAutoUpdate];
	[self updateNav];
}

- (void)didNavRefresh {
	_navRoute = nil;
	_navRouteError = nil;

	_gmsRoutePolyline.map = nil;
	_gmsRoutePolyline = nil;

	_gmsSegmentStartMarker.map = nil;
	_gmsSegmentStartMarker = nil;

	_gmsSegmentEndMarker.map = nil;
	_gmsSegmentEndMarker = nil;

	_gmsSegmentPolyline.map = nil;
	_gmsSegmentPolyline = nil;
	
	_navRouteSegment = NavRouteSegmentMake(-1, -1);
	_navStatus = NavStatus_Unknown;
	_navAutoUpdate = false;
	
	if (_gmsRouteCameraPosition != nil) {
		[self.gmsMapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:_gmsRouteCameraPosition.target zoom:_gmsRouteCameraPosition.zoom]];
		_gmsRouteCameraPosition = nil;
	}
	
	[self updateNav];
	[self buildRoute];
}

- (void)didNavTravelMode {

	if ((0 <= _navTravelModesCtrl.selectedSegmentIndex) && (_navTravelModesCtrl.selectedSegmentIndex < _nsTravelModes.count)) {

		_navRoute = nil;
		_navRouteError = nil;
		
		_gmsRoutePolyline.map = nil;
		_gmsRoutePolyline = nil;
		
		_gmsSegmentStartMarker.map = nil;
		_gmsSegmentStartMarker = nil;

		_gmsSegmentEndMarker.map = nil;
		_gmsSegmentEndMarker = nil;

		_gmsSegmentPolyline.map = nil;
		_gmsSegmentPolyline = nil;

		_navRouteSegment = NavRouteSegmentMake(-1, -1);
		_navStatus = NavStatus_Unknown;
		_navAutoUpdate = false;
		
		[self updateNav];

		NSString *travelMode = [_nsTravelModes objectAtIndex:_navTravelModesCtrl.selectedSegmentIndex];
		[self buildRouteWithTravelMode:travelMode];

		[[NSUserDefaults standardUserDefaults] setObject:travelMode forKey:self.travelModeKey];
	}
}

- (void)didNavAutoUpdate {
	if (_navStatus == NavStatus_Progress) {
		NavRouteSegment segment = [self findNearestRouteSegmentByCurrentLocation];
		if ([_navRoute isValidSegment:segment]) {
			[self applyNavSegment:segment];
			_navAutoUpdate = true;
		}
		[self updateNav];
	}
}

- (void)updateNavByCurrentLocation {
	if ((_navStatus == NavStatus_Progress) && _navAutoUpdate && (_clLocation != nil) && (_navRoute != nil) && [_navRoute isValidSegment:_navRouteSegment]) {
		NavRouteSegment segment = [self findNearestRouteSegmentByCurrentLocation];
		if ([_navRoute isValidSegment:segment]) {
			[self updateNavFromSegment:segment];
		}
	}
}

- (NavRouteSegment)findNearestRouteSegmentByCurrentLocation {
	return ((_clLocation != nil) && (_navRoute != nil)) ?
		[_navRoute findNearestSegmentFromLocation:_clLocation.coordinate] :
		NavRouteSegmentMake(-1, -1);
}

- (void)updateNavFromSegment:(NavRouteSegment)segment {
	if (!NavRouteSegmentIsEqual(_navRouteSegment, segment)) {
		[self applyNavSegment:segment];
		[self updateNav];
	}
}

- (void)applyNavSegment:(NavRouteSegment)segment {
	if (!NavRouteSegmentIsEqual(_navRouteSegment, segment)) {
		_navRouteSegment = segment;
		[self updateOnNavSegment];
	}
}

- (void)updateOnNavSegment {
	NSInteger legIndex = _navRouteSegment.legIndex;
	NavRouteLeg *leg = ((0 <= legIndex) && (legIndex < _navRoute.legs.count)) ? [_navRoute.legs objectAtIndex:legIndex] : nil;

	NSInteger stepIndex = _navRouteSegment.stepIndex;
	NavRouteStep *step = ((0 <= stepIndex) && (stepIndex < leg.steps.count)) ? [leg.steps objectAtIndex:stepIndex] : nil;
	
	GMSCameraUpdate *cameraUpdate = nil;
	if (step != nil) {
		CLLocationCoordinate2D startLocation = step.startLocation.coordinate;
		CLLocationCoordinate2D endLocation = step.endLocation.coordinate;
		if (!CLLocationCoordinate2DIsEqual(startLocation, endLocation)) {
			_gmsSegmentStartMarker.position = startLocation;
			_gmsSegmentStartMarker.map = self.gmsMapView;

			_gmsSegmentEndMarker.position = endLocation;
			_gmsSegmentEndMarker.map = self.gmsMapView;
			
			_gmsSegmentPolyline.path = [GMSPath pathFromEncodedPath:step.polyline.points];
			_gmsSegmentPolyline.map = self.gmsMapView;
			
			GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:_gmsSegmentPolyline.path];
			cameraUpdate = [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
		}
		else {
			_gmsSegmentStartMarker.position = startLocation;
			_gmsSegmentStartMarker.map = self.gmsMapView;
			_gmsSegmentEndMarker.map = nil;
			_gmsSegmentPolyline.map = nil;
			cameraUpdate = [GMSCameraUpdate setTarget:startLocation zoom:self.gmsMapView.camera.zoom];
		}
	}
	else {
		_gmsSegmentStartMarker.map = nil;
		_gmsSegmentEndMarker.map = nil;
		_gmsSegmentPolyline.map = nil;

		GMSCoordinateBounds *bounds = [self buildRouteBounds];
		cameraUpdate = [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
	}
	
	[self.gmsMapView animateWithCameraUpdate:cameraUpdate];
}

- (void)notifyRouteStart {
	[self notifyRouteEvent:@"map.route.start"];
}

- (void)notifyRouteFinish {
	[self notifyRouteEvent:@"map.route.finish"];
}

- (void)notifyRouteEvent:(NSString*)event {
	
	NavCoord *org = _navRoute.legs.firstObject.startLocation;
	NavCoord *dst = _navRoute.legs.lastObject.endLocation;

	NSDictionary *parameters = @{
		@"origin": (org != nil) ? @{
			@"latitude": @(org.latitude),
			@"longitude": @(org.longitude),
		} : [NSNull null],
		@"destination": (dst != nil) ? @{
			@"latitude": @(dst.latitude),
			@"longitude": @(dst.longitude),
		} : [NSNull null],
		@"location": (_clLocation != nil) ? @{
			@"latitude": @(_clLocation.coordinate.latitude),
			@"longitude": @(_clLocation.coordinate.longitude),
			@"timestamp": @(floor(_clLocation.timestamp.timeIntervalSince1970 * 1000.0)), // in milliseconds since 1970-01-01T00:00:00Z
		} : [NSNull null],
	};
	
	[AppDelegate.sharedInstance.flutterMethodChannel invokeMethod:event arguments:parameters.inaJsonString];
}


#pragma mark Utils

- (NSString*)travelModeKey {
	UIUCExploreType exploreType = _explore.uiucExploreType;
	if (exploreType == UIUCExploreType_Explores) {
		exploreType = _explore.uiucExploreContentType;
	}
	NSString *exploreTypeString = UIUCExploreTypeToString(exploreType);
	return (0 < exploreTypeString.length) ? [NSString stringWithFormat:@"%@.%@", kTravelModeKey, exploreTypeString] : kTravelModeKey;
}

- (NSString*)travelModeDefault {
	UIUCExploreType exploreType = _explore.uiucExploreType;
	if (exploreType == UIUCExploreType_Explores) {
		exploreType = _explore.uiucExploreContentType;
	}
	return (exploreType == UIUCExploreType_Parking) ? kNavTravelModeDriving : kNavTravelModeWalking;
}

- (NSInteger)buildTravelModeSegments {
	NSInteger selectedTravelModeIndex = 0;
	NSString *selectedTravelMode = [[NSUserDefaults standardUserDefaults] inaStringForKey:self.travelModeKey defaults:self.travelModeDefault];
	for (NSInteger index = 0; index < _nsTravelModes.count; index++) {
		UIImage *segmentImage = nil;
		NSString *travelMode = [_nsTravelModes objectAtIndex:index];
		if ([travelMode isEqualToString:kNavTravelModeWalking]) {
			segmentImage = [UIImage imageNamed:@"travel-mode-walk"];
		}
		else if ([travelMode isEqualToString:kNavTravelModeBicycling]) {
			segmentImage = [UIImage imageNamed:@"travel-mode-bicycle"];
		}
		else if ([travelMode isEqualToString:kNavTravelModeDriving]) {
			segmentImage = [UIImage imageNamed:@"travel-mode-drive"];
		}
		else if ([travelMode isEqualToString:kNavTravelModeTransit]) {
			segmentImage = [UIImage imageNamed:@"travel-mode-transit"];
		}
		else {
			segmentImage = [UIImage imageNamed:@"travel-mode-unknown"];
		}
		[_navTravelModesCtrl insertSegmentWithImage:segmentImage atIndex:index animated:NO];

		if ([travelMode isEqualToString:selectedTravelMode]) {
			selectedTravelModeIndex = index;
		}
	}
	return selectedTravelModeIndex;
}

- (void)setStepHtml:(NSString*)htmlContent {

	NSString *html = [NSString stringWithFormat:@"<html>\
		<head><style>body{ font-family: Helvetica; font-weight: regular; font-size: 18px; color:#000000 } </style></head>\
		<body><center>%@</center></body>\
	</html>", htmlContent];

	_navStepLabel.attributedText = [[NSAttributedString alloc]
		initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]
		options:@{
			NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
			NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
		}
		documentAttributes:nil
		error:nil
	];
}

- (void)alertMessage:(NSString*)message {
	__weak typeof(self) weakSelf = self;
	if (_alertController != nil) {
		[self dismissViewControllerAnimated:YES completion:^{
			weakSelf.alertController = nil;
			[weakSelf alertMessage:message];
		}];
	}
	else {
		_alertController = [UIAlertController alertControllerWithTitle:self.appTitle message:message preferredStyle:UIAlertControllerStyleAlert];
		[_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			weakSelf.alertController = nil;
		}]];
		[self presentViewController:_alertController animated:YES completion:nil];
	}
}

- (NSString*)appTitle {
	NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if (title.length == 0) {
		title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	}
	return title;
}

#pragma mark GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
	if ([super respondsToSelector:@selector(mapView:idleAtCameraPosition:)]) {
		[super mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position];
	}

	if (_currentZoom != position.zoom) {
		_currentZoom = position.zoom;
		[self updateExploreMarker];
	}
}

@end

/////////////////////////////////
// NavRoute+InaUtils

@implementation NavRoute(InaUtils)

- (bool)isValidSegment:(NavRouteSegment)segment {
	if ((0 <= segment.legIndex) && (segment.legIndex < self.legs.count)) {
		NavRouteLeg *leg = [self.legs objectAtIndex:segment.legIndex];
		if ((0 <= segment.stepIndex) && (segment.stepIndex < leg.steps.count)) {
			return true;
		}
	}
	return false;
}

- (NavRouteSegment)findNearestSegmentFromLocation:(CLLocationCoordinate2D)location {
	double minDelta = DBL_MAX;
	NavRouteSegment minSegment = NavRouteSegmentMake(-1, -1);
	for (NSInteger legIndex = 0; legIndex < self.legs.count; legIndex++) {
		NavRouteLeg *leg = [self.legs objectAtIndex:legIndex];
		for (NSInteger stepIndex = 0; stepIndex < leg.steps.count; stepIndex++) {
			NavRouteStep *step = [leg.steps objectAtIndex:stepIndex];
			double distanceToStart = CLLocationCoordinate2DInaDistance(step.startLocation.coordinate, location);
			double distanceToEnd = CLLocationCoordinate2DInaDistance(location, step.endLocation.coordinate);
			double stepDistance = CLLocationCoordinate2DInaDistance(step.startLocation.coordinate, step.endLocation.coordinate);
			double stepDelta = fabs(distanceToStart) + fabs(distanceToEnd) - fabs(stepDistance);
			if (stepDelta < minDelta) {
				minDelta = stepDelta;
				minSegment = NavRouteSegmentMake(legIndex, stepIndex);
			}
		}
	}
	return minSegment;
}

- (NSString*)displayDecription {
	NSMutableString *displayDecription = [[NSMutableString alloc] init];
	
	// Distance
	NSString *displayDistance = nil;
	if (self.legs.count == 1) {
		displayDistance = self.legs.firstObject.distance.text;
	}
	else {
		NSNumber* totalDistance = self.distance;
		if (0 < totalDistance.integerValue) {
			// 1 foot = 0.3048 meters
			// 1 mile = 1609.34 meters

			long totalMeters = labs(totalDistance.integerValue);
			double totalMiles = totalMeters / 1609.34;
			
			if (0 < displayDecription.length)
				[displayDecription appendString:@", "];
			displayDistance = [NSString stringWithFormat:@"%.*f %@", (totalMiles < 10.0) ? 1 : 0, totalMiles, (totalMiles != 1.0) ? @"miles" : @"mile"];
		}
	}
	if (0 < displayDistance.length) {
		if (0 < displayDecription.length)
			[displayDecription appendString:@", "];
		[displayDecription appendString:displayDistance];
	}

	// Duration
	NSString *displayDuration = nil;
	if (self.legs.count == 1) {
		displayDuration = self.legs.firstObject.duration.text;
	}
	else {
		NSNumber* totalDuration = self.duration;

		if (0 < totalDuration.integerValue) {
			long totalSeconds = labs(totalDuration.integerValue);
			long totalMinutes = totalSeconds / 60;
			long totalHours = totalMinutes / 60;
			
			long minutes = totalMinutes % 60;
			
			if (totalHours < 1)
				displayDuration = [NSString stringWithFormat:@"%lu min", minutes];
			else if (totalHours < 24)
				displayDuration = [NSString stringWithFormat:@"%lu h %02lu min", totalHours, minutes];
			else
				displayDuration = [NSString stringWithFormat:@"%lu h", totalHours];
		}
	}
	if (0 < displayDuration.length) {
		if (0 < displayDecription.length)
			[displayDecription appendString:@", "];
		[displayDecription appendString:displayDuration];
	}

	// Summary
	if ((0 < self.summary.length) && (displayDecription.length == 0)) {
		[displayDecription appendString:self.summary];
	}

	return displayDecription;
}

@end


/////////////////////////////////
// Utility functions

static NavRouteSegment NavRouteSegmentMake(NSInteger legIndex, NSInteger stepIndex) {
	NavRouteSegment segment = {legIndex, stepIndex};
	return segment;
}

static bool NavRouteSegmentIsEqual(NavRouteSegment segment1, NavRouteSegment segment2) {
	return (segment1.legIndex == segment2.legIndex) && (segment1.stepIndex == segment2.stepIndex);
}

