//
//  MapLocationPickerController.m
//  Runner
//
//  Created by Mihail Varbanov on 9/17/19.
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

#import "MapLocationPickerController.h"
#import "AppKeys.h"

#import "NSDictionary+InaTypedValue.h"
#import "NSString+InaJson.h"
#import "UILabel+InaMeasure.h"

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>


@interface MapLocationPickerController () <GMSMapViewDelegate>

@property (nonatomic, strong) NSDictionary*         explore;

@property (nonatomic, strong) GMSMapView*           gmsMapView;

@property (nonatomic, strong) UILabel*              locationLabel;

@property (nonatomic, strong) GMSMarker*            customLocationMarker;
@property (nonatomic, strong) GMSMarker*            selectedMarker;

@end

@implementation MapLocationPickerController

- (instancetype)init {
	if (self = [super init]) {
		self.navigationItem.title = NSLocalizedString(@"Pick Location", nil);
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didSave)];
	}
	return self;
}

- (instancetype)initWithParameters:(NSDictionary*)parameters completionHandler:(FlutterCompletion)completionHandler {
	if (self = [self init]) {
		_parameters = parameters;
		
		id exploreParam = [_parameters objectForKey:@"explore"];
		if ([exploreParam isKindOfClass:[NSDictionary class]]) {
			_explore = exploreParam;
		}

		_completionHandler = completionHandler;
	}
	return self;
}

- (void)loadView {

	NSDictionary *initalLocation = [_explore inaDictForKey:@"location"];
	NSNumber *locationLatitude = [initalLocation inaNumberForKey:@"latitude"];
	NSNumber *locationLongitute = [initalLocation inaNumberForKey:@"longitude"];
	bool hasInitialLocation = ((locationLatitude != nil) && (locationLongitute != nil));
	CLLocationCoordinate2D cameraPos = hasInitialLocation ?
		CLLocationCoordinate2DMake(locationLatitude.doubleValue, locationLongitute.doubleValue) : kInitialCameraLocation;
	float cameraZoom = hasInitialLocation ? 20 : kInitialCameraZoom;
	GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:cameraPos.latitude longitude:cameraPos.longitude zoom:cameraZoom];
	_gmsMapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
	_gmsMapView.delegate = self;

	_locationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	_locationLabel.font = [UIFont systemFontOfSize:16];
	_locationLabel.numberOfLines = 0;
	_locationLabel.textAlignment = NSTextAlignmentCenter;
	_locationLabel.textColor = [UIColor blackColor];
	_locationLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.5];
	_locationLabel.shadowOffset = CGSizeMake(2, 2);
	[_gmsMapView addSubview:_locationLabel];

	self.view = _gmsMapView;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self layoutViews];
}

- (void)layoutViews {
	CGSize contentSize = self.view.frame.size;
	_gmsMapView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);

	CGSize descriptionGutter = CGSizeMake(24, 24);
	CGFloat descriptionX = descriptionGutter.width;
	CGFloat descriptionW = MAX(contentSize.width - 2 * descriptionGutter.width, 0);
	CGFloat descriptionY = UIApplication.sharedApplication.statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height + descriptionGutter.height;
	CGFloat descriptionH = [_locationLabel inaTextSizeForBoundWidth:descriptionW].height;
	_locationLabel.frame = CGRectMake(descriptionX, descriptionY, descriptionW, descriptionH);
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSDictionary *initalLocation = [_explore inaDictForKey:@"location"];
	NSNumber *locationLatitude = [initalLocation inaNumberForKey:@"latitude"];
	NSNumber *locationLongitute = [initalLocation inaNumberForKey:@"longitude"];
	if ((locationLatitude != nil) && (locationLongitute != nil)) {
		_gmsMapView.selectedMarker = _selectedMarker = [self createCustomLocationMarkerFromExploreData:_explore];
	}
	
	[self updateLocationLabelFromMarker:_selectedMarker];
}

#pragma mark Location Handling

- (void)setSelectedLocationMarker:(GMSMarker*)marker {

	if ((_customLocationMarker != nil) && (_customLocationMarker != marker)) {
		[self clearCustomLocationMarker];
	}
	
	_selectedMarker = marker;
	
	[self updateLocationLabelFromMarker:marker];
}

- (void)updateLocationLabelFromMarker:(GMSMarker*)marker {
	if (marker != nil) {
		NSString *locationName = marker.title;
		
		NSString *html = [NSString stringWithFormat:@"<html>\
			<head><style>body{ font-family: Helvetica; font-weight: regular; font-size: 18px; color:#000000 } </style></head>\
			<body><center>%@</center></body>\
		</html>", [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Location", nil), [NSString stringWithFormat:@"<b>%@</b>", locationName]]];

		_locationLabel.attributedText = [[NSAttributedString alloc]
			initWithData:[html dataUsingEncoding:NSUTF8StringEncoding]
			options:@{
				NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
				NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
			}
			documentAttributes:nil
			error:nil
		];
	}
	else {
		_locationLabel.text = NSLocalizedString(@"Please select a location.", nil);
	}
}

- (GMSMarker*)createCustomLocationMarkerAtCoordinate:(CLLocationCoordinate2D)coordinate {

	NSMutableDictionary *explore = [NSMutableDictionary dictionaryWithDictionary:_explore];
	explore[@"location"] = @{
		@"latitude" : @(coordinate.latitude),
		@"longitude" : @(coordinate.longitude),
	};

	return [self createCustomLocationMarkerFromExploreData:explore];
}

- (GMSMarker*)createCustomLocationMarkerFromExploreData:(NSDictionary*)explore {

	NSDictionary *location = [explore inaDictForKey:@"location"];
	NSNumber *locationLatitude = [location inaNumberForKey:@"latitude"];
	NSNumber *locationLongitute = [location inaNumberForKey:@"longitude"];
	if ((locationLatitude == nil) || (locationLongitute == nil)) {
		return nil;
	}

	[self clearCustomLocationMarker];
	
	NSString *title = [location inaStringForKey:@"name"];
	
	if (title.length == 0)
		title = [explore inaStringForKey:@"name"];
	if (title.length == 0)
		title = [NSString stringWithFormat:@"%.06f, %.06f", locationLatitude.doubleValue, locationLongitute.doubleValue];

	NSString *description = [location inaStringForKey:@"description"];
	
	_customLocationMarker = [[GMSMarker alloc] init];
	_customLocationMarker.position = CLLocationCoordinate2DMake(locationLatitude.doubleValue, locationLongitute.doubleValue);
	_customLocationMarker.icon = [UIImage imageNamed:@"maps-icon-location-target"];
	_customLocationMarker.title = title;
	_customLocationMarker.snippet = description;
	_customLocationMarker.zIndex = 1;
	_customLocationMarker.groundAnchor = CGPointMake(0.25, 1.0);
	_customLocationMarker.userData = @{ @"location" : location ?: @{} };
	_customLocationMarker.map = _gmsMapView;
	return _customLocationMarker;
}

- (void)clearCustomLocationMarker {
	if (_customLocationMarker != nil) {
		if (_gmsMapView.selectedMarker == _customLocationMarker) {
			_gmsMapView.selectedMarker = nil;
		}
		if (_selectedMarker == _customLocationMarker) {
			_selectedMarker = nil;
		}
		
		_customLocationMarker.map = nil;
		_customLocationMarker = nil;
	}
}

- (void)didSave {
	if ((_selectedMarker == nil) || (_selectedMarker.map != _gmsMapView))  {
		NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
		if (title.length == 0) {
			title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
		}
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:NSLocalizedString(@"Please select a location.", nil) preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
	}
	else {
		NSDictionary *locationData = nil;
		if (_selectedMarker == _customLocationMarker) {
			locationData = _selectedMarker.userData;
		}
		else {
			locationData = @{ @"location" : @{
				@"latitude" : @(_selectedMarker.position.latitude),
				@"longitude" : @(_selectedMarker.position.longitude),
			}};
		}
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:locationData options:0 error:NULL];
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		if (self.completionHandler != nil) {
			self.completionHandler(jsonString);
			self.completionHandler = nil;
		}
		
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark GMSMapViewDelegate

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(nonnull GMSMarker *)marker {
	[self setSelectedLocationMarker:marker];
	return FALSE; // perform default behavior
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
	if ((_selectedMarker != nil) || (_customLocationMarker != nil)) {
		[self clearCustomLocationMarker];
		[self setSelectedLocationMarker:nil];
		_gmsMapView.selectedMarker = nil;
	}
	else {
		GMSMarker *customLocationMarker = [self createCustomLocationMarkerAtCoordinate:coordinate];
		[self setSelectedLocationMarker:customLocationMarker];
		_gmsMapView.selectedMarker = customLocationMarker;
	}
}

@end

@implementation GMSIndoorLevel(InaUtils)

- (NSNumber*)floor {
	return (0 < self.shortName.length) ? [NSNumber numberWithInteger:self.shortName.integerValue] : nil;
}

- (bool)isEqualToLevel:(GMSIndoorLevel*)level {
	return [self.name isEqualToString:level.name] && [self.shortName isEqualToString:level.shortName];
}

@end

@implementation GMSIndoorBuilding(InaUtils)

- (GMSIndoorLevel*)levelFromFloor:(NSNumber*)floor {
	if (floor != nil) {
		if (0 < floor.integerValue) {
			NSString *floorName = floor.stringValue;
			for (GMSIndoorLevel *level in self.levels) {
				if ([level.shortName isEqualToString:floorName]) {
					return level;
				}
			}
		}
		else if ((0 <= self.defaultLevelIndex) && (self.defaultLevelIndex <= self.levels.count)) {
			return [self.levels objectAtIndex:self.defaultLevelIndex];
		}
	}
	return nil;
}

@end

