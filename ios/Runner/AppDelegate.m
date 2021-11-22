//
//  AppDelegate.m
//  Runner
//
//  Created by Mihail Varbanov on 2/19/19.
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

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import "AppKeys.h"
#import "MapView.h"
#import "MapController.h"
#import "MapDirectionsController.h"
#import "MapLocationPickerController.h"
#import "RegionMonitor.h"
#import "PollPlugin.h"

#import "NSArray+InaTypedValue.h"
#import "NSDictionary+InaTypedValue.h"
#import "NSDictionary+UIUCConfig.h"
#import "CGGeometry+InaUtils.h"
#import "UIColor+InaParse.h"
#import "Bluetooth+InaUtils.h"

#import <GoogleMaps/GoogleMaps.h>
#import <MapsIndoors/MapsIndoors.h>
#import <Firebase/Firebase.h>
#import <ZXingObjC/ZXingObjC.h>

#import <UserNotifications/UserNotifications.h>
#import <SafariServices/SafariServices.h>
#import <PassKit/PassKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const kFIRMessagingFCMTokenNotification = @"com.firebase.iid.notif.fcm-token";

@interface RootNavigationController : UINavigationController
@end

@interface LaunchScreenView : UIView
@end

UIInterfaceOrientation _interfaceOrientationFromString(NSString *value);
NSString* _interfaceOrientationToString(UIInterfaceOrientation value);

UIInterfaceOrientation _interfaceOrientationFromMask(UIInterfaceOrientationMask value);
UIInterfaceOrientationMask _interfaceOrientationToMask(UIInterfaceOrientation value);

@interface AppDelegate()<UINavigationControllerDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, CBPeripheralManagerDelegate, FIRMessagingDelegate, PKAddPassesViewControllerDelegate> {
}

// Flutter
@property (nonatomic) UINavigationController *navigationViewController;
@property (nonatomic) FlutterViewController *flutterViewController;
@property (nonatomic) FlutterMethodChannel *flutterMethodChannel;

// Launch View
@property (nonatomic) UIView *launchScreenView;

// PassKit
@property (nonatomic) PKAddPassesViewController *passViewController;
@property (nonatomic) FlutterResult passFlutterResult;

// Init Keys
@property (nonatomic) NSDictionary* keys;

// Interface Orientations
@property (nonatomic) NSSet *supportedInterfaceOrientations;
@property (nonatomic) UIInterfaceOrientation preferredInterfaceOrientation;

// Location Services
@property (nonatomic) CLLocationManager *clLocationManager;
@property (nonatomic) NSMutableSet<FlutterResult> *locationFlutterResults;

// Bluetooth Services
@property (nonatomic) CBPeripheralManager *peripheralManager;
@property (nonatomic) NSMutableSet<FlutterResult> *bluetoothFlutterResults;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	__weak typeof(self) weakSelf = self;
	
//	Configure the Meridian SDK
//	MRConfig *config = [MRConfig new];
//	config.domainConfig.domainRegion = kMeridianDomainRegion;
//	config.applicationToken = kMeridianAppToken;
//	[Meridian configure:config];

//	Initialize Google Maps SDK
//	[GMSServices provideAPIKey:kGoogleAPIKey];

//	Initialize Maps Indoors SDK
//	[MapsIndoors provideAPIKey:kMapsIndoorsAPIKey googleAPIKey:kGoogleAPIKey];

	// Initialize Firebase SDK
	[FIRApp configure];
	[FIRMessaging messaging].delegate = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveFCMTokenNotification:) name:kFIRMessagingFCMTokenNotification object:nil];
	
	// Initialize Flutter plugins
	[GeneratedPluginRegistrant registerWithRegistry:self];

	// Setup MapPlugin
	NSObject<FlutterPluginRegistrar>*registrar = [self registrarForPlugin:@"MapPlugin"];
	MapViewFactory *factory = [[MapViewFactory alloc] initWithMessenger:registrar.messenger];
	[registrar registerViewFactory:factory withId:@"mapview"];
	
	// Setup PollPlugin
	[PollPlugin registerWithRegistrar:[self registrarForPlugin:@"PollPlugin"]];

	// Setup supported & preffered orientation
	_preferredInterfaceOrientation = UIInterfaceOrientationPortrait;
	_supportedInterfaceOrientations = [NSSet setWithObject:@(_preferredInterfaceOrientation)];

	// Setup root ViewController
	UIViewController *rootViewController = self.window.rootViewController;
	_flutterViewController = [rootViewController isKindOfClass:[FlutterViewController class]] ? (FlutterViewController*)rootViewController : nil;

	_navigationViewController = [[RootNavigationController alloc] initWithRootViewController:rootViewController];
	_navigationViewController.navigationBarHidden = YES;
	_navigationViewController.delegate = self;

	_navigationViewController.navigationBar.translucent = NO;
	_navigationViewController.navigationBar.barTintColor = [UIColor inaColorWithHex:@"13294b"];
	_navigationViewController.navigationBar.tintColor = [UIColor whiteColor];
	_navigationViewController.navigationBar.titleTextAttributes = @{
		NSForegroundColorAttributeName : [UIColor whiteColor]
	};

	[self setupLaunchScreen];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = _navigationViewController;
	[self.window makeKeyAndVisible];
	
	// Listen Method Channel
	_flutterMethodChannel = [FlutterMethodChannel methodChannelWithName:kFlutterMetodChannelName binaryMessenger:_flutterViewController.binaryMessenger];
	[_flutterMethodChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
		[weakSelf handleFlutterAPIFromCall:call result:result];
	}];
	
	// Push Notifications
	[UNUserNotificationCenter currentNotificationCenter].delegate = self;
	[UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
		if ((settings.authorizationStatus != UNAuthorizationStatusNotDetermined) && (settings.authorizationStatus != UNAuthorizationStatusDenied)) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[weakSelf registerForRemoteNotifications];
			});
		}
	}];
	
	return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillTerminate:(UIApplication *)application {

	// Push Notifications
	if (UNUserNotificationCenter.currentNotificationCenter.delegate == self) {
		UNUserNotificationCenter.currentNotificationCenter.delegate = nil;
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super applicationWillTerminate:application];
}

+ (instancetype)sharedInstance {
	id sharedInstance = [UIApplication sharedApplication].delegate;
	return [sharedInstance isKindOfClass:self] ? sharedInstance : nil;
}

#pragma mark LifeCycle

-(void)applicationDidEnterForeground:(UIApplication *)application{
	NSLog(@"applicationDidEnterForeground:");
}

-(void)applicationDidEnterBackground:(UIApplication *)application{
	NSLog(@"applicationDidEnterBackground:");
}

#pragma mark Launch Screen

- (void)setupLaunchScreen {

	if (_launchScreenView != nil) {
		[_launchScreenView removeFromSuperview];
	}
	
	UIView *parentView = _navigationViewController.viewControllers.firstObject.view;
	_launchScreenView = [[LaunchScreenView alloc] initWithFrame:CGRectMake(0, 0, parentView.bounds.size.width, parentView.bounds.size.height)];
	_launchScreenView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[parentView addSubview:_launchScreenView];
}

- (void)removeLaunchScreen {
	if (_launchScreenView != nil) {
		__weak typeof(self) weakSelf = self;
		[UIView animateWithDuration:0.5 animations:^{
			weakSelf.launchScreenView.alpha = 0;
		} completion:^(BOOL finished) {
			[weakSelf.launchScreenView removeFromSuperview];
			weakSelf.launchScreenView = nil;
		}];
	}
}

#pragma mark Flutter APIs

- (void)handleFlutterAPIFromCall:(FlutterMethodCall*)call result:(FlutterResult)result {
	NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
	if ([call.method isEqualToString:@"init"]) {
		[self handleInitWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"directions"]) {
		[self handleDirectionsWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"pickLocation"]) {
		[self handlePickLocationWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"map"]) {
		[self handleMapWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"showNotification"]) {
		[self handleShowNotificationWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"dismissSafariVC"]) {
		[self handleDismissSafariVCWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"dismissLaunchScreen"]) {
		[self handleDismissLaunchScreenWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"firebaseInfo"]) {
		[self handleFirebaseInfoWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"notifications_authorization"]) {
		[self handleNotificationsWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"location_services_permission"]) {
		[self handleLocationServicesWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"bluetooth_authorization"]) {
		[self handleBluetoothAuthorizationWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"addToWallet"]) {
		[self handleAddToWalletWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"geoFence"]) {
		[self handleGeoFenceWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"deviceId"]) {
		[self handleDeviceIdWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"enabledOrientations"]) {
		[self handleEnabledOrientationsWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"barcode"]) {
		[self handleBarcodeWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"test"]) {
		[self handleTestWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"launchApp"]) {
		[self handleLaunchApp:parameters result:result];
	}
}

- (void)handleInitWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	self.keys = [parameters inaDictForKey:@"keys"];
	
	// Configure the Meridian SDK
	NSString *meridianApplicationToken = [_keys uiucConfigStringForPathKey:@"meridian.app_token"];
	int meridianDomainRegion = [_keys uiucConfigIntForPathKey:@"meridian.domain_region"];
	if (meridianApplicationToken != nil) {
		MRConfig *config = [MRConfig new];
		config.applicationToken = meridianApplicationToken;
		config.domainConfig.domainRegion = meridianDomainRegion;
		[Meridian configure:config];
	}
	
	// Initialize Google Maps SDK
	NSString *googleMapsAPIKey = [_keys uiucConfigStringForPathKey:@"google.maps.api_key"];
	if (0 < googleMapsAPIKey.length) {
		[GMSServices provideAPIKey:googleMapsAPIKey];
	}

	// Initialize Maps Indoors SDK
	NSString *mapsIndoorsAPIKey = [_keys uiucConfigStringForPathKey:@"mapsindoors.api_key"];
	if ((0 < mapsIndoorsAPIKey.length) && (0 < googleMapsAPIKey.length)) {
		[MapsIndoors provideAPIKey:mapsIndoorsAPIKey googleAPIKey:googleMapsAPIKey];
	}

	result(@(YES));
}

- (void)handleDirectionsWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	MapDirectionsController *directionsController = [[MapDirectionsController alloc] initWithParameters:parameters completionHandler:^(id returnValue) {
		result(returnValue);
	}];
	[self.navigationViewController pushViewController:directionsController animated:YES];
}

- (void)handlePickLocationWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	MapLocationPickerController *pickLocationController = [[MapLocationPickerController alloc] initWithParameters:parameters completionHandler:^(id returnValue) {
		result(returnValue);
	}];
	[self.navigationViewController pushViewController:pickLocationController animated:YES];
}

- (void)handleMapWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	MapController *mapController = [[MapController alloc] initWithParameters:parameters completionHandler:^(id returnValue) {
		result(returnValue);
	}];
	[self.navigationViewController pushViewController:mapController animated:YES];
}

- (void)handleShowNotificationWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
	content.title = [parameters inaStringForKey:@"title"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	content.subtitle = [parameters inaStringForKey:@"subtitle"];
	content.body = [parameters inaStringForKey:@"body"];
	content.sound = [parameters inaBoolForKey:@"sound" defaults:true] ? [UNNotificationSound defaultSound] : nil;
	
	UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
												  triggerWithTimeInterval:1 repeats:NO];
	
	UNNotificationRequest* request = [UNNotificationRequest
									  requestWithIdentifier:@"Poll_Created" content:content trigger:trigger];
	
	UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
	[center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
		if (error != nil) {
			NSLog(@"%@", error.localizedDescription);
		}
	}];
}

- (void)handleDismissSafariVCWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	UIViewController *presentedController = self.flutterViewController.presentedViewController;
	if ([presentedController isKindOfClass:[SFSafariViewController class]]) {
		[presentedController dismissViewControllerAnimated:YES completion:^{
			result(@(YES));
		}];
	}
	else {
		result(@(NO));
	}
}

- (void)handleDismissLaunchScreenWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	[self removeLaunchScreen];
}

- (void)handleFirebaseInfoWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
    FIRApp *firApp = [FIRApp defaultApp];
    FIROptions *options = (firApp != nil) ? [firApp options] : nil;
    NSString *projectID = (options != nil) ? [options projectID] : nil;
    result(projectID);
}

- (void)handleNotificationsWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *method = [parameters inaStringForKey:@"method"];
	if ([method isEqualToString:@"query"]) {
		[self queryNotificationsAuthorizationWithFlutterResult:result];
	}
	else if ([method isEqualToString:@"request"]) {
		[self requestNotificationsAuthorizationWithFlutterResult:result];
	}
	else {
		result(nil);
	}
}

- (void)handleLocationServicesWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *method = [parameters inaStringForKey:@"method"];
	if ([method isEqualToString:@"query"]) {
		[self queryLocationServicesPermisionWithFlutterResult:result];
	}
	else if ([method isEqualToString:@"request"]) {
		[self requestLocationServicesPermisionWithFlutterResult:result];
	}
	else {
		result(nil);
	}
}

- (void)handleBluetoothAuthorizationWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *method = [parameters inaStringForKey:@"method"];
	if ([method isEqualToString:@"query"]) {
		[self queryBluetoothAuthorizationWithFlutterResult:result];
	}
	else if ([method isEqualToString:@"request"]) {
		[self requestBluetoothAuthorizationWithFlutterResult:result];
	}
	else {
		result(nil);
	}
}


- (void)handleAddToWalletWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *base64CardData = [parameters inaStringForKey:@"cardBase64Data"];
	NSData *cardData = [[NSData alloc] initWithBase64EncodedString:base64CardData options:0];
	[self addPassToWallet:cardData result:result];
	result(nil);
}

- (void)handleGeoFenceWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSArray *regions;
	NSDictionary *beacons;
	if ((regions = [parameters inaArrayForKey:@"regions"]) != nil) {
		[RegionMonitor.sharedInstance monitorRegions:regions];
		result(RegionMonitor.sharedInstance.currentRegionIdsList);
	}
	else if ((beacons = [parameters inaDictForKey:@"beacons"]) != nil) {
		NSString *regionId = [beacons inaStringForKey:@"regionId"];
		NSString *action = [beacons inaStringForKey:@"action"];
		if ([action isEqualToString:@"start"]) {
			result(@([RegionMonitor.sharedInstance startRangingBeaconsInRegionWithId:regionId]));
		}
		else if ([action isEqualToString:@"stop"]) {
			result(@([RegionMonitor.sharedInstance stopRangingBeaconsInRegionWithId:regionId]));
		}
		else {
			result([RegionMonitor.sharedInstance beaconsInRegionWithId:regionId]);
		}
	}
	else {
		result(nil);
	}
}

- (void)handleDeviceIdWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	result(self.deviceUUID.UUIDString);
}

- (void)handleTestWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	result(nil);
}

- (void)handleLaunchApp:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *deepLink = [parameters inaStringForKey:@"deep_link"];
	NSURL *deepLinkUrl = deepLink != nil ? [NSURL URLWithString:deepLink] : nil;
	if([UIApplication.sharedApplication canOpenURL:deepLinkUrl]){
		[UIApplication.sharedApplication openURL:deepLinkUrl options:@{} completionHandler:^(BOOL success) {
			result([NSNumber numberWithBool:success]);
		}];
	} else {
		result([NSNumber numberWithBool:NO]);
	}
}

#pragma mark Barcode

- (void)handleBarcodeWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *content = [parameters inaStringForKey:@"content"];
	NSString *formatName = [parameters inaStringForKey:@"format"];
	int width = [parameters inaIntForKey:@"width"];
	int height = [parameters inaIntForKey:@"height"];

	ZXBarcodeFormat format = 0;
	if ([formatName isEqualToString:@"aztec"]) {
		format = kBarcodeFormatAztec;
	} else if ([formatName isEqualToString:@"codabar"]) {
		format = kBarcodeFormatCodabar;
	} else if ([formatName isEqualToString:@"code39"]) {
		format = kBarcodeFormatCode39;
	} else if ([formatName isEqualToString:@"code93"]) {
		format = kBarcodeFormatCode93;
	} else if ([formatName isEqualToString:@"code128"]) {
		format = kBarcodeFormatCode128;
	} else if ([formatName isEqualToString:@"dataMatrix"]) {
		format = kBarcodeFormatDataMatrix;
	} else if ([formatName isEqualToString:@"ean8"]) {
		format = kBarcodeFormatEan8;
	} else if ([formatName isEqualToString:@"ean13"]) {
		format = kBarcodeFormatEan13;
	} else if ([formatName isEqualToString:@"itf"]) {
		format = kBarcodeFormatITF;
	} else if ([formatName isEqualToString:@"maxiCode"]) {
		format = kBarcodeFormatMaxiCode;
	} else if ([formatName isEqualToString:@"pdf417"]) {
		format = kBarcodeFormatPDF417;
	} else if ([formatName isEqualToString:@"qrCode"]) {
		format = kBarcodeFormatQRCode;
	} else if ([formatName isEqualToString:@"rss14"]) {
		format = kBarcodeFormatRSS14;
	} else if ([formatName isEqualToString:@"rssExpanded"]) {
		format = kBarcodeFormatRSSExpanded;
	} else if ([formatName isEqualToString:@"upca"]) {
		format = kBarcodeFormatUPCA;
	} else if ([formatName isEqualToString:@"upce"]) {
		format = kBarcodeFormatUPCE;
	} else if ([formatName isEqualToString:@"upceanExtension"]) {
		format = kBarcodeFormatUPCEANExtension;
	}
	
	NSError *error = nil;
	UIImage *image = nil;
	ZXEncodeHints *hints = [ZXEncodeHints hints];
	hints.margin = @(0);
	ZXBitMatrix* matrix = [[ZXMultiFormatWriter writer] encode:content format:format width:width height:height hints:hints error:&error];
	if (matrix != nil) {
		CGImageRef imageRef = CGImageRetain([[ZXImage imageWithMatrix:matrix] cgimage]);
		image = [UIImage imageWithCGImage:imageRef];
		CGImageRelease(imageRef);
	}
	
	NSData *imageData = (image != nil) ? UIImagePNGRepresentation(image) : nil;
	NSString *base64ImageData = (imageData != nil) ? [imageData base64EncodedStringWithOptions:0] : nil;
	result(base64ImageData);
}

/*
//#import "NKDBarcodeFramework.h"
#import "NKDBarcode.h"
#import "NKDBarcodeOffscreenView.h"
#import "NKDCode39Barcode.h"
#import "NKDExtendedCode39Barcode.h"
#import "NKDInterleavedTwoOfFiveBarcode.h"
#import "NKDModifiedPlesseyBarcode.h"
#import "NKDPostnetBarcode.h"
#import "NKDUPCABarcode.h"
#import "NKDModifiedPlesseyHexBarcode.h"
#import "NKDIndustrialTwoOfFiveBarcode.h"
#import "NKDEAN13Barcode.h"
#import "NKDCode128Barcode.h"
#import "NKDCodabarBarcode.h"
#import "UIImage-NKDBarcode.h"
#import "UIImage-Normalize.h"
#import "NKDUPCEBarcode.h"
#import "NKDEAN8Barcode.h"
#import "NKDRoyalMailBarcode.h"
#import "NKDPlanetBarcode.h"

- (void)handleBarcodeWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *content = [parameters inaStringForKey:@"content"];
	NSString *formatName = [parameters inaStringForKey:@"format"];
	float barWidth = [parameters inaFloatForKey:@"barWidth"];
	float height = [parameters inaFloatForKey:@"height"];

	NKDBarcode *format = nil;
	if ([formatName isEqualToString:@"codabar"]) {
		format = [NKDCodabarBarcode alloc];
	} else if ([formatName isEqualToString:@"code39"]) {
		format = [NKDCode39Barcode alloc];
	} else if ([formatName isEqualToString:@"code128"]) {
		format = [NKDCode128Barcode alloc];
	} else if ([formatName isEqualToString:@"upca"]) {
		format = [NKDUPCABarcode alloc];
	} else if ([formatName isEqualToString:@"upce"]) {
		format = [NKDUPCEBarcode alloc];
	} else if ([formatName isEqualToString:@"ean13"]) {
		format = [NKDEAN13Barcode alloc];
	} else if ([formatName isEqualToString:@"ean8"]) {
		format = [NKDEAN8Barcode alloc];

	} else if ([formatName isEqualToString:@"code93ext"]) {
		format = [NKDExtendedCode39Barcode alloc];
	} else if ([formatName isEqualToString:@"plesseyMod"]) {
		format = [NKDModifiedPlesseyBarcode alloc];
	} else if ([formatName isEqualToString:@"plesseyModHex"]) {
		format = [NKDModifiedPlesseyHexBarcode alloc];
	} else if ([formatName isEqualToString:@"postnet"]) {
		format = [NKDPostnetBarcode alloc];
	} else if ([formatName isEqualToString:@"industrial"]) {
		format = [NKDIndustrialTwoOfFiveBarcode alloc];
	}

	format = [format initWithContent:content printsCaption:NO andBarWidth:barWidth andHeight:height andFontSize:0 andCheckDigit:(char)-1];

	UIImage *image = (format != nil) ? [UIImage imageFromBarcode:format] : nil; // ..or as a less accu
	NSData *imageData = (image != nil) ? UIImagePNGRepresentation(image) : nil;
	NSString *base64ImageData = (imageData != nil) ? [imageData base64EncodedStringWithOptions:0] : nil;
	result(base64ImageData);
}
*/

#pragma mark Orientations

- (void)handleEnabledOrientationsWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {

	NSMutableArray *resultList = [[NSMutableArray alloc] init];
	if (_preferredInterfaceOrientation != UIInterfaceOrientationUnknown) {
		[resultList addObject:_interfaceOrientationToString(_preferredInterfaceOrientation)];
	}
	for (NSNumber *supportedOrienation in _supportedInterfaceOrientations) {
		if (supportedOrienation.intValue != _preferredInterfaceOrientation) {
			[resultList addObject:_interfaceOrientationToString(supportedOrienation.intValue)];
		}
	}
	
	NSArray *orientationsList = [parameters inaArrayForKey:@"orientations"];
	if (orientationsList != nil) {
		UIInterfaceOrientation preferredInterfaceOrientation = UIInterfaceOrientationUnknown;
		NSMutableSet *supportedOrientations = [[NSMutableSet alloc] init];
		for (NSString *orientationString in orientationsList) {
			UIInterfaceOrientation orientation = ([orientationString isKindOfClass:[NSString class]]) ? _interfaceOrientationFromString(orientationString) : UIInterfaceOrientationUnknown;
			if (orientation != UIInterfaceOrientationUnknown) {
				[supportedOrientations addObject:@(orientation)];
				if (preferredInterfaceOrientation == UIInterfaceOrientationUnknown) {
					preferredInterfaceOrientation = orientation;
				}
			}
		}
		
		if ((preferredInterfaceOrientation != UIInterfaceOrientationUnknown) && (_preferredInterfaceOrientation != preferredInterfaceOrientation)) {
			_preferredInterfaceOrientation = preferredInterfaceOrientation;
		}
		
		if ((0 < supportedOrientations.count) && ![_supportedInterfaceOrientations isEqualToSet:supportedOrientations]) {
			_supportedInterfaceOrientations = supportedOrientations;
			UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
			if (![_supportedInterfaceOrientations containsObject:@(currentOrientation)]) {
				[[UIDevice currentDevice] setValue:@(_preferredInterfaceOrientation) forKey:@"orientation"];
			}
		}
	}
	
	result(resultList);
	
}

/*
[_navigationViewController.topViewController presentViewController:[[UIViewController alloc] init] animated:NO completion:^{
	[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(closeForceOrientationConrtoller:) userInfo:nil repeats:NO];
}];
- (void)closeForceOrientationConrtoller:(NSTimer*)timer {
	[_navigationViewController.topViewController dismissViewControllerAnimated:NO completion:nil];
}
*/

#pragma mark Push Notifications

- (void)queryNotificationsAuthorizationWithFlutterResult:(FlutterResult)result {
	[UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
		result([self.class notificationServicesPermisionFromAuthorizationStatus:settings.authorizationStatus]);
	}];
}

+ (NSString*)notificationServicesPermisionFromAuthorizationStatus:(UNAuthorizationStatus)authorizationStatus {
	switch (authorizationStatus) {
		case UNAuthorizationStatusNotDetermined:       return @"not_determined";
		case UNAuthorizationStatusDenied:              return @"denied";
		default:                                       return @"allowed";
	}
	return nil;
}


- (void)requestNotificationsAuthorizationWithFlutterResult:(FlutterResult)result {
	__weak typeof(self) weakSelf = self;
	[UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* settings) {
		if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
			result([self.class notificationServicesPermisionFromAuthorizationStatus:UNAuthorizationStatusDenied]);
		}
		else {
			UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
			[UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error){
				dispatch_async(dispatch_get_main_queue(), ^{
					result([self.class notificationServicesPermisionFromAuthorizationStatus:granted ? UNAuthorizationStatusAuthorized : UNAuthorizationStatusDenied]);
					if (granted) {
						[weakSelf registerForRemoteNotifications];
					}
				});
			}];
		}
	}];
}

- (void)registerForRemoteNotifications {
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
	[[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
	NSLog(@"UIApplication didRegisterForRemoteNotificationsWithDeviceToken: %@", [NSString stringWithFormat:@"%@", deviceToken]);
	[FIRMessaging messaging].APNSToken = deviceToken;
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
	NSLog(@"UIApplication didFailToRegisterForRemoteNotificationsWithError: %@", error);
}

- (void)processPushNotification:(NSDictionary*)userInfo {
	[[FIRMessaging messaging] appDidReceiveMessage:userInfo];
}

#pragma mark LocationServices

- (void)queryLocationServicesPermisionWithFlutterResult:(FlutterResult)result {
	NSString *status = [CLLocationManager locationServicesEnabled] ?
		[self.class locationServicesPermisionFromAuthorizationStatus:[CLLocationManager authorizationStatus]] :
		@"disabled";
	result(status);
}

+ (NSString*)locationServicesPermisionFromAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus {
	switch (authorizationStatus) {
		case kCLAuthorizationStatusNotDetermined:       return @"not_determined";
		case kCLAuthorizationStatusRestricted:          return @"denied";
		case kCLAuthorizationStatusDenied:              return @"denied";
		case kCLAuthorizationStatusAuthorizedAlways:    return @"allowed";
		case kCLAuthorizationStatusAuthorizedWhenInUse: return @"allowed";
	}
	return nil;
}

- (void)requestLocationServicesPermisionWithFlutterResult:(FlutterResult)flutterResult {
	if ([CLLocationManager locationServicesEnabled]) {
		CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
		if (status == kCLAuthorizationStatusNotDetermined) {
			if (_locationFlutterResults == nil) {
				_locationFlutterResults = [[NSMutableSet alloc] init];
			}
			[_locationFlutterResults addObject:flutterResult];

			if (_clLocationManager == nil) {
				_clLocationManager = [[CLLocationManager alloc] init];
				_clLocationManager.delegate = self;
				[_clLocationManager requestAlwaysAuthorization];
			}
		}
		else {
			flutterResult([self.class locationServicesPermisionFromAuthorizationStatus:status]);
		}
	}
	else {
		flutterResult([self.class locationServicesPermisionFromAuthorizationStatus:kCLAuthorizationStatusRestricted]);
	}
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {

	if (status != kCLAuthorizationStatusNotDetermined) {
		_clLocationManager.delegate = nil;
		_clLocationManager = nil;

		NSSet<FlutterResult> *flutterResults = _locationFlutterResults;
		_locationFlutterResults = nil;

		for(FlutterResult flutterResult in flutterResults) {
			flutterResult([self.class locationServicesPermisionFromAuthorizationStatus:status]);
		}
	}
}

#pragma mark Bluetooth Authorization

- (void)queryBluetoothAuthorizationWithFlutterResult:(FlutterResult)flutterResult {
	flutterResult(InaBluetoothAuthorizationStatusToString(InaBluetooth.peripheralAuthorizationStatus));
}

- (void)requestBluetoothAuthorizationWithFlutterResult:(FlutterResult)flutterResult {
	if (InaBluetooth.peripheralAuthorizationStatus == InaBluetoothAuthorizationStatusNotDetermined) {
		if (_bluetoothFlutterResults == nil) {
			_bluetoothFlutterResults = [[NSMutableSet alloc] init];
		}
		[_bluetoothFlutterResults addObject:flutterResult];
		if (_peripheralManager == nil) {
			_peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
		}
	}
	else {
		flutterResult(InaBluetoothAuthorizationStatusToString(InaBluetooth.peripheralAuthorizationStatus));
	}
}

- (void)didBluetoothServicesPermision {
	_peripheralManager.delegate = nil;
	_peripheralManager = nil;
	
	NSSet<FlutterResult> *flutterResults = _bluetoothFlutterResults;
	_bluetoothFlutterResults = nil;

	NSString *status = InaBluetoothAuthorizationStatusToString(InaBluetooth.peripheralAuthorizationStatus);
	for (FlutterResult flutterResult in flutterResults) {
		flutterResult(status);
	}
}

#pragma mark CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager*)peripheral {
	[self didBluetoothServicesPermision];
}

#pragma mark Deep Links

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
	NSLog(@"UIApplication handleOpenURL: %@", url.absoluteString);
	if ([super respondsToSelector:@selector(application:openURL:options:)]) {
		return [super application:app openURL:url options:options];
	}
	else {
		return FALSE;
	}
}

#pragma mark PassKit

- (void)addPassToWallet:(NSData*)passData result:(FlutterResult)result {
	if (_passViewController != nil) {
		NSLog(@"PassKit: currently adding a pass");
		result(@(NO));
	}
	else if (!PKAddPassesViewController.canAddPasses) {
		NSLog(@"PassKit: cannot add passes");
		result(@(NO));
	}
	else {
		NSError *error = nil;
		PKPass *pass = [[PKPass alloc] initWithData:passData error:&error];
		if ((pass != nil) && (error == nil)) {
			PKAddPassesViewController *passViewController = [[PKAddPassesViewController alloc] initWithPass:pass];
			if (passViewController != nil) {
				__weak typeof(self) weakSelf = self;
				passViewController.delegate = self;
				[_navigationViewController.topViewController presentViewController:passViewController animated:YES completion:^{
					weakSelf.passFlutterResult = result;
					weakSelf.passViewController = passViewController;
				}];
			}
			else {
				NSLog(@"PassKit: failed to create add pass controller");
				result(@(NO));
			}
		}
		else {
			NSLog(@"PassKit: failed to create pass: %@", error.localizedDescription);
			result(@(NO));
		}
	}
}


#pragma mark Device UUID

- (NSUUID*)deviceUUID {
	static const NSString *deviceUUID = @"deviceUUID";

	NSDictionary *spec = @{
		(id)kSecClass:       (id)kSecClassGenericPassword,
		(id)kSecAttrAccount: deviceUUID,
		(id)kSecAttrGeneric: deviceUUID,
		(id)kSecAttrService: NSBundle.mainBundle.bundleIdentifier,
	};
	
	NSMutableDictionary *searchRequest = [NSMutableDictionary dictionaryWithDictionary:spec];
	[searchRequest setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[searchRequest setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
  [searchRequest setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];

	CFDictionaryRef response = NULL;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)searchRequest, (CFTypeRef*)&response);
	if (status == errSecInteractionNotAllowed) {
		// Could not access data. Error: errSecInteractionNotAllowed
		return nil;
	}
	else if (status == 0) {
		NSDictionary *attribs = CFBridgingRelease(response);
		NSData *data = [attribs objectForKey:(id)kSecValueData];
		NSString *security = [attribs objectForKey:(id)kSecAttrAccessible];

		// If not always accessible then update it to be so
		if (![security isEqualToString:(id)kSecAttrAccessibleAlways]) {
			NSDictionary *update = @{
				(id)kSecAttrAccessible:(id)kSecAttrAccessibleAlways,
				(id)kSecValueData:data ?: [[NSData alloc] init],
			};

			SecItemUpdate((CFDictionaryRef)spec, (CFDictionaryRef)update);
		}

		if (data.length == sizeof(uuid_t)) {
			return [[NSUUID alloc] initWithUUIDBytes:data.bytes];
		}
		else {
			// update entry bellow
		}
	}

	uuid_t uuidData;
	int rndStatus = SecRandomCopyBytes(kSecRandomDefault, sizeof(uuidData), uuidData);
	if (rndStatus == errSecSuccess) {
		if (status == 0) {
			// update existing entry
			NSDictionary *update = @{
				(id)kSecAttrAccessible:(id)kSecAttrAccessibleAlways,
				(id)kSecValueData:[NSData dataWithBytes:uuidData length:sizeof(uuidData)]
			};
			status = SecItemUpdate((CFDictionaryRef)spec, (CFDictionaryRef)update);
		}
		else {
			// create new entry
			NSMutableDictionary *createRequest = [NSMutableDictionary dictionaryWithDictionary:spec];
			[createRequest setObject:[NSData dataWithBytes:uuidData length:sizeof(uuidData)] forKey:(id)kSecValueData];
			[createRequest setObject:(id)kSecAttrAccessibleAlways forKey:(id)kSecAttrAccessible];
			status = SecItemAdd((CFDictionaryRef)createRequest, NULL);
		}
		return (status == 0) ? [[NSUUID alloc] initWithUUIDBytes:uuidData] : nil;
	}
	else {
		return nil;
	}
}

#pragma mark PKAddPassesViewControllerDelegate

- (void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller {
	if (controller == _passViewController) {
		__weak typeof(self) weakSelf = self;
		[controller dismissViewControllerAnimated:YES completion:^{
			FlutterResult result = weakSelf.passFlutterResult;
			weakSelf.passFlutterResult = nil;
			weakSelf.passViewController = nil;
			if (result != nil) {
				result(@(YES));
			}
		}];
	}
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	UIViewController *rootViewController = navigationController.viewControllers.firstObject;
	BOOL navigationBarHidden = (viewController == rootViewController);
	if (navigationController.navigationBarHidden != navigationBarHidden) {
		[navigationController setNavigationBarHidden:navigationBarHidden animated:YES];
	}
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {

}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
	if ([fromVC conformsToProtocol:@protocol(FlutterCompletionHandler)] && [toVC isKindOfClass:[FlutterViewController class]]) {
		id<FlutterCompletionHandler> directionsVC = (id<FlutterCompletionHandler>)fromVC;
		if (directionsVC.completionHandler != nil) {
			directionsVC.completionHandler(nil);
			directionsVC.completionHandler = nil;
		}
	}
	
	return nil;
}


#pragma mark UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
	NSDictionary *userInfo = notification.request.content.userInfo;
	NSData *userInfoData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:NULL];
	NSString *userInfoString = [[NSString alloc] initWithData:userInfoData encoding:NSUTF8StringEncoding];
	NSLog(@"UIApplication: UNUserNotificationCenter willPresentNotification:\n%@", userInfoString);
	
	completionHandler(UNNotificationPresentationOptionAlert|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
	NSDictionary *userInfo = response.notification.request.content.userInfo;
	NSData *userInfoData = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:NULL];
	NSString *userInfoString = [[NSString alloc] initWithData:userInfoData encoding:NSUTF8StringEncoding];
	NSLog(@"UIApplication: UNUserNotificationCenter didReceiveNotificationResponse (%@):\n%@", response.actionIdentifier, userInfoString);

	if ([response.actionIdentifier isEqualToString:UNNotificationDismissActionIdentifier]) {
		// The user dismissed the notification without taking action.
	}
	else if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
		// The user launched the app.
		[self processPushNotification:response.notification.request.content.userInfo];
	}

	completionHandler();
}

#pragma mark FIRMessagingDelegate

- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
	NSLog(@"UIApplication: FIRMessaging: didReceiveRegistrationToken: %@", fcmToken);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:fcmToken forKey:@"token"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FCMToken" object:nil userInfo:userInfo];
}

#pragma mark NSNotificationCenter

- (void)didReceiveFCMTokenNotification:(NSNotification *)notification {
	NSString *fcmToken = [notification.object isKindOfClass:[NSString class]] ? notification.object : nil;
	NSLog(@"UIApplication: didReceiveFCMTokenNotification: %@", fcmToken);
}

@end

//////////////////////////////////////
// RootNavigationController

@implementation RootNavigationController

- (BOOL)shouldAutorotate {
	return true;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	UIInterfaceOrientationMask result = 0;
	for (NSNumber *orientation in AppDelegate.sharedInstance.supportedInterfaceOrientations) {
		result |= _interfaceOrientationToMask(orientation.integerValue);
	}
	
	return result;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	return AppDelegate.sharedInstance.preferredInterfaceOrientation;
}

@end

//////////////////////////////////////
// UIInterfaceOrientation

@interface LaunchScreenView()
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIActivityIndicatorView *activityView;
@end

@implementation LaunchScreenView

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_imageView = [[UIImageView alloc] initWithFrame:frame];
		_imageView.image = [UIImage imageNamed:@"LaunchImage"];
		[self addSubview:_imageView];
		
		_activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[self addSubview:_activityView];

		[_activityView startAnimating];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGSize contentSize = self.frame.size;
	
	CGSize imageSize = InaSizeScaleToFill(_imageView.image.size, contentSize);
	_imageView.frame = CGRectMake((contentSize.width - imageSize.width) / 2, (contentSize.height - imageSize.height) / 2, imageSize.width, imageSize.height);
	
	CGSize activitySize = [_activityView sizeThatFits:contentSize];
	_activityView.frame = CGRectMake((contentSize.width - activitySize.width) / 2, 7 * (contentSize.height - activitySize.height) / 8, activitySize.width, activitySize.height);
	
	
}

@end


//////////////////////////////////////
// UIInterfaceOrientation

UIInterfaceOrientation _interfaceOrientationFromString(NSString *value) {
	if ([value isEqualToString:@"portraitUp"]) {
		return UIInterfaceOrientationPortrait;
	}
	else if ([value isEqualToString:@"portraitDown"]) {
		return UIInterfaceOrientationPortraitUpsideDown;
	}
	else if ([value isEqualToString:@"landscapeLeft"]) {
		return UIInterfaceOrientationLandscapeLeft;
	}
	else if ([value isEqualToString:@"landscapeRight"]) {
		return UIInterfaceOrientationLandscapeRight;
	}
	else {
		return UIInterfaceOrientationUnknown;
	}
}

NSString* _interfaceOrientationToString(UIInterfaceOrientation value) {
	switch (value) {
		case UIInterfaceOrientationPortrait: return @"portraitUp";
		case UIInterfaceOrientationPortraitUpsideDown: return @"portraitDown";
		case UIInterfaceOrientationLandscapeLeft: return @"landscapeLeft";
		case UIInterfaceOrientationLandscapeRight: return @"landscapeRight";
		default: return nil;
	}
}

UIInterfaceOrientation _interfaceOrientationFromMask(UIInterfaceOrientationMask value) {
	switch (value) {
		case UIInterfaceOrientationMaskPortrait: return UIInterfaceOrientationPortrait;
		case UIInterfaceOrientationMaskPortraitUpsideDown: return UIInterfaceOrientationPortraitUpsideDown;
		case UIInterfaceOrientationMaskLandscapeLeft: return UIInterfaceOrientationLandscapeLeft;
		case UIInterfaceOrientationMaskLandscapeRight: return UIInterfaceOrientationLandscapeRight;
		default: return UIInterfaceOrientationUnknown;
	}
}

UIInterfaceOrientationMask _interfaceOrientationToMask(UIInterfaceOrientation value) {
	switch (value) {
		case UIInterfaceOrientationPortrait: return UIInterfaceOrientationMaskPortrait;
		case UIInterfaceOrientationPortraitUpsideDown: return UIInterfaceOrientationMaskPortraitUpsideDown;
		case UIInterfaceOrientationLandscapeLeft: return UIInterfaceOrientationMaskLandscapeLeft;
		case UIInterfaceOrientationLandscapeRight: return UIInterfaceOrientationMaskLandscapeRight;
		default: return 0;
	}
}

