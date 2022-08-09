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

@interface MPRoute(InaUtils)
- (bool)isValidSegmentPath:(MPRouteSegmentPath)segmentPath;
- (NSString*)displayDecription;
@end

static MPRouteSegmentPath MPRouteSegmentPathMake(NSInteger legIndex, NSInteger stepIndex);

static MPTravelMode const kTravelModes[] = { MPTravelModeWalking, MPTravelModeBicycling, MPTravelModeDriving, MPTravelModeTransit };
static NSString * const kTravelModeKey = @"mapDirections.travelMode";

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

@property (nonatomic, strong) UISegmentedControl*   navTravelModesCtrl;
@property (nonatomic, strong) UIButton*             navRefreshButton;
@property (nonatomic, strong) UIButton*             navAutoUpdateButton;
@property (nonatomic, strong) UIButton*             navPrevButton;
@property (nonatomic, strong) UIButton*             navNextButton;
@property (nonatomic, strong) UILabel*              navStepLabel;
@property (nonatomic)         NavStatus             navStatus;
@property (nonatomic)         bool                  navAutoUpdate;
@property (nonatomic)         bool                  navDidFirstLocationUpdate;

@property (nonatomic, strong) MPRoute*              mpRoute;
@property (nonatomic, strong) NSError*              mpRouteError;
@property (nonatomic, strong) GMSPolyline*          gmsRoutePolyline;
@property (nonatomic, strong) GMSCameraPosition*    gmsRouteCameraPosition;
@property (nonatomic, strong) NSArray*              nsRouteStepCoordsCounts;
@property (nonatomic, strong) MPDirectionsService*  mpRouteService;
@property (nonatomic, strong) MPDirectionsRenderer* mpDirectionsRenderer;
@property (nonatomic, strong) GMSMarker*            gmsExploreMarker;
@property (nonatomic, strong) GMSPolygon*           gmsExplorePolygone;

@end

/////////////////////////////////
// MapDirectionsController

@implementation MapDirectionsController

- (instancetype)init {
	if (self = [super init]) {
		self.navigationItem.title = NSLocalizedString(@"Directions", nil);
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateNav];
	[self prepare];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
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
			
			if (_mpPositionResult != nil) {
				// Position camera on user location
				CLLocationCoordinate2D currentLocationCoord = CLLocationCoordinate2DMake(_mpPositionResult.geometry.lat, _mpPositionResult.geometry.lng);
				GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate setTarget:currentLocationCoord];
				[self.gmsMapView moveCamera:cameraUpdate];
			}
		}
	}
	else if (_mpPositionResult == nil) {
		// Show map and present error message
		if (self.gmsMapView.hidden) {
			self.gmsMapView.hidden = false;
			[_activityIndicator stopAnimating];
			[_activityStatus setText:@""];
			
			// Position camera on explore location
			CLLocationCoordinate2D exploreLocationCoord = CLLocationCoordinate2DMake([_exploreLocation inaDoubleForKey:@"latitude"], [_exploreLocation inaDoubleForKey:@"longitude"]);
			GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate setTarget:exploreLocationCoord];
			[self.gmsMapView moveCamera:cameraUpdate];
			
			[self updateNav];

			// Alert error
			NSString *message = nil;
			if (0 < self.mrLocationError.localizedDescription.length) {
				message = self.mrLocationError.localizedDescription;
			}
			else if (0 < self.clLocationError.localizedDescription.length) {
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
		if ((_mpRouteService == nil) && (_mpRoute == nil) && (_mpRouteError == nil)) {
			[self buildRoute];
		}
	}
}

- (void)buildRoute {
	MPTravelMode travelMode = ((0 <= _navTravelModesCtrl.selectedSegmentIndex) && (_navTravelModesCtrl.selectedSegmentIndex < _countof(kTravelModes))) ? kTravelModes[_navTravelModesCtrl.selectedSegmentIndex] : MPTravelModeWalking;;
	[self buildRouteWithTravelMode:travelMode];
}

- (void)buildRouteWithTravelMode:(MPTravelMode)travelMode {
	[_activityStatus setText:NSLocalizedString(@"Looking for route...", nil)];
	[_activityIndicator startAnimating];

	MPPoint *orgPoint = _mpPositionResult.geometry;
	MPPoint *dstPoint = [[MPPoint alloc] initWithLat:[_exploreLocation inaDoubleForKey:@"latitude"] lon:[_exploreLocation inaDoubleForKey:@"longitude"] zValue:[_exploreLocation inaIntegerForKey:@"floor"]];
	
	NSLog(@"Lookup Route: [%.6f, %.6f] @ level %d -> [%.6f, %.6f] @ level %d", orgPoint.lat, orgPoint.lng, orgPoint.zIndex, dstPoint.lat, dstPoint.lng, dstPoint.zIndex);

	MPDirectionsQuery *query = [[MPDirectionsQuery alloc] initWithOriginPoint:orgPoint destination:dstPoint];
	query.travelMode = travelMode;
	
	__weak typeof(self) weakSelf = self;
	MPDirectionsService *mpRouteService = _mpRouteService = [[MPDirectionsService alloc] init];
	[_mpRouteService routingWithQuery:query completionHandler:^(MPRoute * _Nullable route, NSError * _Nullable error) {
		if (mpRouteService == weakSelf.mpRouteService) {
			weakSelf.mpRouteService = nil;
			weakSelf.mpRoute = route;
			weakSelf.mpRouteError = error;
			[weakSelf didBuildRoute];
		}
	}];
}

- (void)didBuildRoute {
	
	self.gmsMapView.hidden = false;
	[_activityIndicator stopAnimating];
	[_activityStatus setText:@""];

	if (_mpRoute != nil) {
		[self buildRoutePolyline];
		
		_mpDirectionsRenderer = [[MPDirectionsRenderer alloc] init];
		_mpDirectionsRenderer.map = self.gmsMapView;
		_mpDirectionsRenderer.route = _mpRoute;
		
		_gmsRouteCameraPosition = self.gmsMapView.camera;
		
		_navStatus = NavStatus_Start;

	}
	[self updateNav];

	GMSMutablePath *path = [[GMSMutablePath alloc] init];
	[path addLatitude:_mpPositionResult.geometry.lat longitude:_mpPositionResult.geometry.lng]; // current location
	[path addLatitude:[_exploreLocation inaDoubleForKey:@"latitude"] longitude:[_exploreLocation inaDoubleForKey:@"longitude"]]; // explore location

	NSArray *explorePolygon = _explore.uiucExplorePolygon;
	if (0 < explorePolygon.count) {
		for (NSDictionary *point in explorePolygon) {
			if ([point isKindOfClass:[NSDictionary class]]) {
				[path addLatitude:[point inaDoubleForKey:@"latitude"] longitude:[point inaDoubleForKey:@"longitude"]];
			}
		}
	}

	GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];

	if (_mpRoute.bounds != nil) {
		bounds = [bounds includingCoordinate:CLLocationCoordinate2DMake(_mpRoute.bounds.northeast.lat.doubleValue, _mpRoute.bounds.northeast.lng.doubleValue)];
		bounds = [bounds includingCoordinate:CLLocationCoordinate2DMake(_mpRoute.bounds.southwest.lat.doubleValue, _mpRoute.bounds.southwest.lng.doubleValue)];
	}
	GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
	[self.gmsMapView moveCamera:cameraUpdate];

	if (_mpRoute == nil) {
		NSString *message = nil;
		if (0 < _mpRouteError.localizedDescription.length) {
			message = _mpRouteError.localizedDescription;
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
		_gmsExploreMarker.position = CLLocationCoordinate2DMake([_exploreLocation inaDoubleForKey:@"latitude"], [_exploreLocation inaDoubleForKey:@"longitude"]);

		MapMarkerView *iconView = [MapMarkerView createFromExplore:_explore];
		_gmsExploreMarker.iconView = iconView;
		_gmsExploreMarker.title = iconView.title;
		_gmsExploreMarker.snippet = iconView.descr;
		_gmsExploreMarker.groundAnchor = iconView.anchor;
		_gmsExploreMarker.zIndex = 1;
		_gmsExploreMarker.userData = @{ @"explore" : _explore };
		_gmsExploreMarker.map = self.gmsMapView;
		[self updateExploreMarker];
	}
}

- (void)updateExploreMarker {
	NSDictionary *explore = [_gmsExploreMarker.userData inaDictForKey:@"explore"];
	NSDictionary *exploreLocation = [explore inaDictForKey:@"location"];
	NSNumber *markerFloor = [exploreLocation inaNumberForKey:@"floor"];

	MapMarkerView *iconView = [_gmsExploreMarker.iconView isKindOfClass:[MapMarkerView class]] ? ((MapMarkerView*)_gmsExploreMarker.iconView) : nil;
	if (iconView != nil) {
		iconView.displayMode =  (self.gmsMapView.camera.zoom < kMarkerThresold1Zoom) ? MapMarkerDisplayMode_Plain : ((self.gmsMapView.camera.zoom < kMarkerThresold2Zoom) ? MapMarkerDisplayMode_Title : MapMarkerDisplayMode_Extended);
		iconView.blurred = ((markerFloor != nil) && (markerFloor.intValue != self.mpMapControl.currentFloor.intValue));
	}
}

- (void)buildExplorePolygon {
	NSArray *explorePolygon = _explore.uiucExplorePolygon;
	if (0 < explorePolygon.count) {
		GMSMutablePath *path = [[GMSMutablePath alloc] init];
		for (NSDictionary *point in explorePolygon) {
			if ([point isKindOfClass:[NSDictionary class]]) {
				[path addLatitude:[point inaDoubleForKey:@"latitude"] longitude:[point inaDoubleForKey:@"longitude"]];
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
	NSMutableArray *routeCounts = [[NSMutableArray alloc] init];
	GMSMutablePath *routePath = [[GMSMutablePath alloc] init];
	for (MPRouteLeg *mpLeg in _mpRoute.legs) {
		for (MPRouteStep *mpStep in mpLeg.steps) {
			GMSPath *gmStepPath = [GMSPath pathFromEncodedPath:mpStep.polyline.points];
			for (NSInteger index = 0; index < gmStepPath.count; index++) {
				[routePath addCoordinate:[gmStepPath coordinateAtIndex:index]];
			}
			[routeCounts addObject:@(gmStepPath.count)];
		}
	}
	
	_nsRouteStepCoordsCounts = routeCounts;
	_gmsRoutePolyline = [GMSPolyline polylineWithPath:routePath];
	//_gmsRoutePolyline.strokeColor = [UIColor inaColorWithHex:@"e84a27"];
	_gmsRoutePolyline.map = self.gmsMapView;
}

- (void)clearRoutePolyline {

}

#pragma mark Navigation

- (void)updateNav {
	bool errorState = (self.mrLocationError != nil) && (self.clLocationError != nil) && (_mpPositionResult == nil);
	
	_navRefreshButton.hidden = errorState;
	_navRefreshButton.enabled = (_mpRouteService == nil);

	_navTravelModesCtrl.hidden = ((_navStatus != NavStatus_Unknown) && (_navStatus != NavStatus_Start)) || errorState;
	_navTravelModesCtrl.enabled = (_mpRouteService == nil);

	_navAutoUpdateButton.hidden = (_navStatus != NavStatus_Progress) || _navAutoUpdate || errorState;
	_navPrevButton.hidden = _navNextButton.hidden = _navStepLabel.hidden = (_navStatus == NavStatus_Unknown);

	if (_navStatus == NavStatus_Start) {
		NSString *routeDescription = _mpRoute.displayDecription;
		[self setStepHtml:[NSString stringWithFormat:@"<b>%@</b>%@",
			NSLocalizedString(@"START", nil),
			(0 < routeDescription.length) ? [NSString stringWithFormat:@"<br>(%@)", routeDescription] : @""
		]];

		_navPrevButton.enabled = false;
		_navNextButton.enabled = true;
	}
	else if (_navStatus == NavStatus_Progress) {
		NSInteger legIndex = _mpDirectionsRenderer.routeLegIndex;
		MPRouteLeg *leg = ((0 <= legIndex) && (legIndex < _mpDirectionsRenderer.route.legs.count)) ? [_mpDirectionsRenderer.route.legs objectAtIndex:legIndex] : nil;
		
		NSInteger stepIndex = _mpDirectionsRenderer.routeStepIndex;
		MPRouteStep *step = ((0 <= stepIndex) && (stepIndex < leg.steps.count)) ? [leg.steps objectAtIndex:stepIndex] : nil;

		if (0 < step.html_instructions.length) {
			[self setStepHtml:step.html_instructions];
		}
		else if ((0 < step.maneuver.length) || (0 < step.highway.length) || (0 < step.routeContext.length)) {
			_navStepLabel.text = [NSString stringWithFormat:@"%@ | %@ | %@", step.routeContext, step.highway, step.maneuver];
		}
		else if ((0 < step.distance.intValue) || (0 < step.duration.intValue)) {
			_navStepLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d m / %d sec", nil), step.distance.intValue, step.duration.intValue];
		}
		else {
			_navStepLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Leg %d / Step %d", nil), (int)legIndex + 1, (int)stepIndex + 1];
		}

		_navPrevButton.enabled = _navNextButton.enabled = true;
		
		NSLog(@"At Route Step (%d:%d): [%.6f, %.6f] @ level %d -> [%.6f, %.6f] @ level %d", (int)legIndex, (int)stepIndex, step.start_location.lat.doubleValue, step.start_location.lng.doubleValue, step.start_location.zLevel.intValue, step.end_location.lat.doubleValue, step.end_location.lng.doubleValue, step.end_location.zLevel.intValue);
		
		[self updateCurerntFloor:step.start_location.zLevel];
	}
	else if (_navStatus == NavStatus_Finished) {
		[self setStepHtml:[NSString stringWithFormat:@"<b>%@</b>", NSLocalizedString(@"FINISH", nil)]];

		_navPrevButton.enabled = true;
		_navNextButton.enabled = false;
	}
}

- (void)updateNavAutoUpdate {
	MPRouteSegmentPath segmentPath = [self findNearestRouteSegmentByCurrentLocation];
	_navAutoUpdate = [_mpRoute isValidSegmentPath:segmentPath] && (_mpDirectionsRenderer.routeLegIndex == segmentPath.legIndex) && (_mpDirectionsRenderer.routeStepIndex == segmentPath.stepIndex);
}

- (void)didNavPrev {
	if (_navStatus == NavStatus_Start) {
	}
	else if (_navStatus == NavStatus_Progress) {
		NSInteger legIndex = _mpDirectionsRenderer.routeLegIndex;
		NSInteger stepIndex = _mpDirectionsRenderer.routeStepIndex;
		
		if (0 < stepIndex) {
			_mpDirectionsRenderer.routeStepIndex = --stepIndex;
		}
		else if (0 < legIndex) {
			_mpDirectionsRenderer.routeLegIndex = --legIndex;
			MPRouteLeg *leg = [_mpDirectionsRenderer.route.legs objectAtIndex:legIndex];
			_mpDirectionsRenderer.routeStepIndex = leg.steps.count - 1;
		}
		else {
			_navStatus = NavStatus_Start;
			_mpDirectionsRenderer.routeLegIndex = _mpDirectionsRenderer.routeStepIndex = -1;
		}
	}
	else if (_navStatus == NavStatus_Finished) {
		_navStatus = NavStatus_Progress;
		
		_mpDirectionsRenderer.routeLegIndex = _mpDirectionsRenderer.route.legs.count - 1;

		MPRouteLeg *leg = _mpDirectionsRenderer.route.legs.lastObject;
		_mpDirectionsRenderer.routeStepIndex = leg.steps.count - 1;
	}
	
	[self updateNavAutoUpdate];
	[self updateNav];
}

- (void)didNavNext {
	if (_navStatus == NavStatus_Start) {
		_navStatus = NavStatus_Progress;
		_mpDirectionsRenderer.routeLegIndex = _mpDirectionsRenderer.routeStepIndex = 0;
		[self notifyRouteStart];
	}
	else if (_navStatus == NavStatus_Progress) {
		NSInteger legIndex = _mpDirectionsRenderer.routeLegIndex;
		NSInteger stepIndex = _mpDirectionsRenderer.routeStepIndex;

		MPRouteLeg *leg = ((0 <= legIndex) && (legIndex < _mpDirectionsRenderer.route.legs.count)) ? [_mpDirectionsRenderer.route.legs objectAtIndex:legIndex] : nil;
		
		if ((stepIndex + 1) < leg.steps.count) {
			_mpDirectionsRenderer.routeStepIndex = ++stepIndex;
		}
		else if ((legIndex + 1) < _mpDirectionsRenderer.route.legs.count) {
			_mpDirectionsRenderer.routeLegIndex = ++legIndex;
			_mpDirectionsRenderer.routeStepIndex = 0;
		}
		else {
			_navStatus = NavStatus_Finished;
			_mpDirectionsRenderer.routeLegIndex = _mpDirectionsRenderer.routeStepIndex = -1;
			[self notifyRouteFinish];
		}
	}
	else if (_navStatus == NavStatus_Finished) {
	}

	[self updateNavAutoUpdate];
	[self updateNav];
}

- (void)didNavRefresh {
	_mpRoute = nil;
	_mpRouteError = nil;
	_gmsRoutePolyline.map = nil;
	_gmsRoutePolyline = nil;
	_nsRouteStepCoordsCounts = nil;
	
	_mpDirectionsRenderer.map = nil;
	_mpDirectionsRenderer.route = nil;
	_mpDirectionsRenderer = nil;
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

	if ((0 <= _navTravelModesCtrl.selectedSegmentIndex) && (_navTravelModesCtrl.selectedSegmentIndex < _countof(kTravelModes))) {

		_mpRoute = nil;
		_mpRouteError = nil;
		_gmsRoutePolyline.map = nil;
		_gmsRoutePolyline = nil;
		_nsRouteStepCoordsCounts = nil;
		
		_mpDirectionsRenderer.map = nil;
		_mpDirectionsRenderer.route = nil;
		_mpDirectionsRenderer = nil;
		_navStatus = NavStatus_Unknown;
		_navAutoUpdate = false;
		
		[self updateNav];

		MPTravelMode travelMode = kTravelModes[_navTravelModesCtrl.selectedSegmentIndex];
		[self buildRouteWithTravelMode:travelMode];

		[[NSUserDefaults standardUserDefaults] setInteger:travelMode forKey:self.travelModeKey];
	}
}

- (void)didNavAutoUpdate {
	if (_navStatus == NavStatus_Progress) {
		MPRouteSegmentPath segmentPath = [self findNearestRouteSegmentByCurrentLocation];
		if ([_mpRoute isValidSegmentPath:segmentPath]) {
			_mpDirectionsRenderer.routeLegIndex = segmentPath.legIndex;
			_mpDirectionsRenderer.routeStepIndex = segmentPath.stepIndex;
			_navAutoUpdate = true;
		}
		[self updateNav];
	}
}

- (void)updateNavByCurrentLocation {
	if ((_navStatus == NavStatus_Progress) && _navAutoUpdate && (_mpPositionResult != nil) &&  (_mpRoute != nil) && (_mpDirectionsRenderer != nil)) {
		MPRouteSegmentPath segmentPath = [self findNearestRouteSegmentByCurrentLocation];
		if ([_mpRoute isValidSegmentPath:segmentPath]) {
			[self updateNavFromPathSegment:segmentPath];
		}
	}
}

- (MPRouteSegmentPath)findNearestRouteSegmentByCurrentLocation {

	if ((_mpPositionResult != nil) && (_mpRoute != nil)) {
		
		MPRouteSegmentPath segmentPath = [_mpRoute findNearestRouteSegmentPathFromPoint:_mpPositionResult.geometry floor:_mpPositionResult.getFloor];
		if ([_mpRoute isValidSegmentPath:segmentPath]) {
			return segmentPath;
		}
		
		double minLegDistance = -1;
		MPRouteSegmentPath minSegmentPath = MPRouteSegmentPathMake(-1, -1);
		CLLocationCoordinate2D locationCoord = CLLocationCoordinate2DMake(_mpPositionResult.geometry.lat, _mpPositionResult.geometry.lng);
		NSInteger globalStepIndex = 0, coordIndex = 0;

		for (NSInteger legIndex = 0; legIndex < _mpRoute.legs.count; legIndex++) {

			MPRouteLeg *mpLeg = [_mpRoute.legs objectAtIndex:legIndex];
			for (NSInteger stepIndex = 0; stepIndex < mpLeg.steps.count; stepIndex++) {

				NSInteger lastCoord = coordIndex + [_nsRouteStepCoordsCounts inaIntegerAtIndex:globalStepIndex];
				while (coordIndex < lastCoord) {

					CLLocationCoordinate2D coord = [_gmsRoutePolyline.path coordinateAtIndex:coordIndex];
					double coordDistance = CLLocationCoordinate2DInaDistance(locationCoord, coord);
					if ((minLegDistance < 0.0) || (coordDistance < minLegDistance)) {
						minLegDistance = coordDistance;
						minSegmentPath = MPRouteSegmentPathMake(legIndex, stepIndex);
						
						// nothing more to do inside current step, go to next one
						coordIndex = lastCoord;
						break;
					}
					coordIndex++;
				}
				globalStepIndex++;
			}
		}
		return minSegmentPath;
	}
	
	return MPRouteSegmentPathMake(-1, -1);
}

- (void)updateNavFromPathSegment:(MPRouteSegmentPath)segmentPath {
	bool modified = false;
	if (_mpDirectionsRenderer.routeLegIndex != segmentPath.legIndex) {
		_mpDirectionsRenderer.routeLegIndex = segmentPath.legIndex;
		modified = true;
	}
	if (_mpDirectionsRenderer.routeStepIndex != segmentPath.stepIndex) {
		_mpDirectionsRenderer.routeStepIndex = segmentPath.stepIndex;
		modified = true;
	}
	if (modified) {
		[self updateNav];
	}
}

- (void)notifyRouteStart {
	[self notifyRouteEvent:@"map.route.start"];
}

- (void)notifyRouteFinish {
	[self notifyRouteEvent:@"map.route.finish"];
}

- (void)notifyRouteEvent:(NSString*)event {
	
	MPRouteCoordinate *org = _mpRoute.legs.firstObject.start_location;
	MPRouteCoordinate *dest = _mpRoute.legs.lastObject.end_location;
	MPPoint *loc = _mpPositionResult.geometry;
	
	NSDate *datestamp = nil;
	switch(_mpPositionProviderSource) {
		case MPPositionProviderSource_Meridian:     datestamp = self.mrLocation.timestamp; break;
		case MPPositionProviderSource_CoreLocation: datestamp = self.clLocation.timestamp; break;
	}
	NSInteger timestamp = floor(datestamp.timeIntervalSince1970 * 1000.0); // in milliseconds since 1970-01-01T00:00:00Z

	NSDictionary *parameters = @{
		@"origin": (org != nil) ? @{
			@"latitude": org.lat,
			@"longitude": org.lng,
			@"floor": org.zLevel,
		} : [NSNull null],
		@"destination": (dest != nil) ? @{
			@"latitude": dest.lat,
			@"longitude": dest.lng,
			@"floor": dest.zLevel,
		} : [NSNull null],
		@"location": (loc != nil) ? @{
			@"latitude": @(loc.lat),
			@"longitude": @(loc.lng),
			@"floor": @(loc.zIndex),
			@"timestamp": @(timestamp),
		} : [NSNull null],
	};
	
	[AppDelegate.sharedInstance.flutterMethodChannel invokeMethod:event arguments:parameters.inaJsonString];
}


#pragma mark Location

- (void)notifyLocationUpdate:(MPPositionResult*)positionResult source:(MPPositionProviderSource) source {
	[super notifyLocationUpdate:positionResult source:source];

	if (_mpPositionResult != nil) {

		if (!_navDidFirstLocationUpdate /* && ((_mrLocation != nil) || (0 < _mrLocationTimeoutsCount)) */) {
			_navDidFirstLocationUpdate = true;
			[self didFirstLocationUpdate];
		}
		
		if ((_navStatus == NavStatus_Progress) && _navAutoUpdate) {
			[self updateNavByCurrentLocation];
		}
		else {
			[self updateNav];
		}
	}
}

- (void)notifyLocationFail {

	if ((self.mrLocationError != nil) && (self.clLocationError != nil) && (_mpPositionResult == nil)) {
		if (!_navDidFirstLocationUpdate) {
			_navDidFirstLocationUpdate = true;
			[self didFirstLocationUpdate];
		}
		else {
			[self updateNav];
		}
	}

	[super notifyLocationFail];
}

#pragma mark Utils

- (void)updateCurerntFloor:(NSNumber*)floor {
	if ((floor != nil) && ([floor integerValue] != [self.mpMapControl.currentFloor integerValue])) {
		self.mpMapControl.currentFloor = floor;
		[self floorDidChange:floor];
	}
}

- (NSString*)travelModeKey {
	UIUCExploreType exploreType = _explore.uiucExploreType;
	if (exploreType == UIUCExploreType_Explores) {
		exploreType = _explore.uiucExploreContentType;
	}
	NSString *exploreTypeString = UIUCExploreTypeToString(exploreType);
	return (0 < exploreTypeString.length) ? [NSString stringWithFormat:@"%@.%@", kTravelModeKey, exploreTypeString] : kTravelModeKey;
}

- (MPTravelMode)travelModeDefault {
	UIUCExploreType exploreType = _explore.uiucExploreType;
	if (exploreType == UIUCExploreType_Explores) {
		exploreType = _explore.uiucExploreContentType;
	}
	return (exploreType == UIUCExploreType_Parking) ? MPTravelModeDriving : MPTravelModeWalking;
}

- (NSInteger)buildTravelModeSegments {
	NSInteger selectedTravelModeIndex = 0;
	MPTravelMode selectedTravelMode = [[NSUserDefaults standardUserDefaults] inaIntegerForKey:self.travelModeKey defaults:self.travelModeDefault];
	for (NSInteger index = 0; index < _countof(kTravelModes); index++) {
		UIImage *segmentImage = nil;
		switch (kTravelModes[index]) {
			case MPTravelModeWalking:   segmentImage = [UIImage imageNamed:@"travel-mode-walk"]; break;
			case MPTravelModeBicycling: segmentImage = [UIImage imageNamed:@"travel-mode-bicycle"]; break;
			case MPTravelModeDriving:   segmentImage = [UIImage imageNamed:@"travel-mode-drive"]; break;
			case MPTravelModeTransit:   segmentImage = [UIImage imageNamed:@"travel-mode-transit"]; break;
			default:                    segmentImage = [UIImage imageNamed:@"travel-mode-unknown"]; break;
		}
		[_navTravelModesCtrl insertSegmentWithImage:segmentImage atIndex:index animated:NO];
		if (selectedTravelMode == kTravelModes[index]) {
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

#pragma mark MPMapControlDelegate

- (void)floorDidChange:(NSNumber*)floor {
	if ([super respondsToSelector:@selector(floorDidChange:)]) {
		[super floorDidChange:floor];
	}
	[self updateExploreMarker];
}

@end

/////////////////////////////////
// MPRoute+InaUtils

@implementation MPRoute(InaUtils)

- (bool)isValidSegmentPath:(MPRouteSegmentPath)segmentPath {
	if ((0 <= segmentPath.legIndex) && (segmentPath.legIndex < self.legs.count)) {
		MPRouteLeg *leg = [self.legs objectAtIndex:segmentPath.legIndex];
		if ((0 <= segmentPath.stepIndex) && (segmentPath.stepIndex < leg.steps.count)) {
			return true;
		}
	}
	return false;
}

- (NSString*)displayDecription {
	NSMutableString *displayDecription = [[NSMutableString alloc] init];

	if (0 < self.distance.integerValue) {
		// 1 foot = 0.3048 meters
		// 1 mile = 1609.34 meters

		long totalMeters = labs(self.distance.integerValue);
		double totalMiles = totalMeters / 1609.34;
		
		if (0 < displayDecription.length)
			[displayDecription appendString:@", "];
		[displayDecription appendFormat:@"%.*f %@", (totalMiles < 10.0) ? 1 : 0, totalMiles, (totalMiles != 1.0) ? @"miles" : @"mile"];
	}
	
	if (0 < self.duration.integerValue) {
		long totalSeconds = labs(self.duration.integerValue);
		long totalMinutes = totalSeconds / 60;
		long totalHours = totalMinutes / 60;
		
		long minutes = totalMinutes % 60;
		
		if (0 < displayDecription.length)
			[displayDecription appendString:@", "];
		if (totalHours < 1)
			[displayDecription appendFormat:@"%lu min", minutes];
		else if (totalHours < 24)
			[displayDecription appendFormat:@"%lu h %02lu min", totalHours, minutes];
		else
			[displayDecription appendFormat:@"%lu h", totalHours];
	}
	
	if ((0 < self.summary.length) && (displayDecription.length == 0)) {
		[displayDecription appendString:self.summary];
	}

	return displayDecription;
}

@end

/////////////////////////////////
// Utility functions

static MPRouteSegmentPath MPRouteSegmentPathMake(NSInteger legIndex, NSInteger stepIndex) {
	MPRouteSegmentPath segmentPath = {legIndex, stepIndex};
	return segmentPath;
}



