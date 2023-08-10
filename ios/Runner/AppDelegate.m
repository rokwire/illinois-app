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
#import "MobileAccessPlugin.h"
#import "FlutterCompletion.h"

#import "NSArray+InaTypedValue.h"
#import "NSDictionary+InaTypedValue.h"
#import "NSDictionary+UIUCConfig.h"
#import "CGGeometry+InaUtils.h"
#import "UIColor+InaParse.h"
#import "UILabel+InaMeasure.h"
#import "Security+UIUCUtils.h"

#import <GoogleMaps/GoogleMaps.h>
#import <Firebase/Firebase.h>
#import <ZXingObjC/ZXingObjC.h>

#import <UserNotifications/UserNotifications.h>

static NSString *const kFIRMessagingFCMTokenNotification = @"com.firebase.iid.notif.fcm-token";

@interface RootNavigationController : UINavigationController
- (void)setNeedsUpdateOfSupportedInterfaceOrientationsIfPossible;
@end

@interface LaunchScreenView : UIView
@property (nonatomic) NSString *statusText;
@end

UIInterfaceOrientation _interfaceOrientationFromString(NSString *value);
NSString* _interfaceOrientationToString(UIInterfaceOrientation value);

UIInterfaceOrientation _interfaceOrientationFromMask(UIInterfaceOrientationMask value);
UIInterfaceOrientationMask _interfaceOrientationToMask(UIInterfaceOrientation value);

@interface AppDelegate()<UINavigationControllerDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate> {
}

// Flutter
@property (nonatomic) RootNavigationController *navigationViewController;
@property (nonatomic) FlutterViewController *flutterViewController;
@property (nonatomic) FlutterMethodChannel *flutterMethodChannel;

// Launch View
@property (nonatomic) LaunchScreenView *launchScreenView;

// Init Keys
@property (nonatomic) NSDictionary* config;

// Interface Orientations
@property (nonatomic) NSSet *supportedInterfaceOrientations;
@property (nonatomic) UIInterfaceOrientation preferredInterfaceOrientation;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	__weak typeof(self) weakSelf = self;
	
	_backgroundOperationQueue = [[NSOperationQueue alloc] init];
	
//	Initialize Google Maps SDK
//	[GMSServices provideAPIKey:kGoogleAPIKey];

	// Initialize Firebase SDK
	[FIRApp configure];
	[FIRMessaging messaging].delegate = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveFCMTokenNotification:) name:kFIRMessagingFCMTokenNotification object:nil];
	
	// Initialize Flutter plugins
	[GeneratedPluginRegistrant registerWithRegistry:self];
    
	// Setup MobileAccessPlugin
	[MobileAccessPlugin registerWithRegistrar:[self registrarForPlugin:@"MobileAccessPlugin"]];
	
	// Setup supported & preffered orientation
	_preferredInterfaceOrientation = UIInterfaceOrientationPortrait;
	_supportedInterfaceOrientations = [NSSet setWithObject:@(_preferredInterfaceOrientation)];

	// Setup root ViewController
	UIViewController *rootViewController = self.window.rootViewController;
	_flutterViewController = [rootViewController isKindOfClass:[FlutterViewController class]] ? (FlutterViewController*)rootViewController : nil;

	_navigationViewController = [[RootNavigationController alloc] initWithRootViewController:rootViewController];
	_navigationViewController.navigationBarHidden = YES;
	[_navigationViewController setNeedsUpdateOfSupportedInterfaceOrientationsIfPossible];
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
	
	[_backgroundOperationQueue cancelAllOperations];

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

- (void)removeLaunchScreenWithCompletionHandler:(FlutterCompletion)completionHandler {
	if (_launchScreenView != nil) {
		__weak typeof(self) weakSelf = self;
		[UIView animateWithDuration:0.5 animations:^{
			weakSelf.launchScreenView.alpha = 0;
		} completion:^(BOOL finished) {
			[weakSelf.launchScreenView removeFromSuperview];
			weakSelf.launchScreenView = nil;
			completionHandler(nil);
		}];
	}
}

- (void)setLaunchScreenStatusText:(NSString*)statusText {
	if (_launchScreenView != nil) {
		_launchScreenView.statusText = statusText;
	}
}

#pragma mark Config

- (NSDictionary*)secretKeys {
	return [_config inaDictForKey:@"secretKeys"];
}

- (NSDictionary*)thirdPartyServices {
	return [_config inaDictForKey:@"thirdPartyServices"];
}

#pragma mark Flutter APIs

- (void)handleFlutterAPIFromCall:(FlutterMethodCall*)call result:(FlutterResult)result {
	NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
	if ([call.method isEqualToString:@"init"]) {
		[self handleInitWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"dismissLaunchScreen"]) {
		[self handleDismissLaunchScreenWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"setLaunchScreenStatus"]) {
		[self handleSetLaunchScreenStatusWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"enabledOrientations"]) {
		[self handleEnabledOrientationsWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"barcode"]) {
		[self handleBarcodeWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"deepLinkScheme"]) {
		[self handleDeepLinkSchemeWithParameters:parameters result:result];
	}
	else if ([call.method isEqualToString:@"test"]) {
		[self handleTestWithParameters:parameters result:result];
	}
}

- (void)handleInitWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	self.config = [parameters inaDictForKey:@"config"];
	
	// Initialize Google Maps SDK
	NSString *googleMapsAPIKey = [self.secretKeys uiucConfigStringForPathKey:@"google.maps.api_key"];
	if (0 < googleMapsAPIKey.length) {
		[GMSServices provideAPIKey:googleMapsAPIKey];
	}

	// Initialize Орiго SDK
	NSString *origoAppId = [self.secretKeys uiucConfigStringForPathKey:@"origo.app_id"];
	if (0 < origoAppId.length) {
		MobileAccessPlugin.sharedInstance.origoAppId = origoAppId;
	}

	result(@(YES));
}

- (void)handleDismissLaunchScreenWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	[self removeLaunchScreenWithCompletionHandler:^(id returnValue) {
		result(returnValue);
	}];
}

- (void)handleSetLaunchScreenStatusWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *statusText = [parameters inaStringForKey:@"status"];
	[self setLaunchScreenStatusText:statusText];
	result(nil);
}

- (void)handleTestWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	result(nil);
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

#pragma mark DeepLink Scheme

- (void)handleDeepLinkSchemeWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
	NSString *deepLinkScheme = nil;
	NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleURLTypes"];
	if ([urlTypes isKindOfClass:[NSArray class]]) {
		for (NSUInteger index = 0; index < urlTypes.count; index++) {
			NSDictionary *urlType = [urlTypes inaDictAtIndex: index];
			NSString *urlName = [urlType inaStringForKey:@"CFBundleURLName"];
			if ([urlName isEqualToString:@"edu.illinois.rokwire.auth"]) {
				NSArray *urlSchemes = [urlType inaArrayForKey:@"CFBundleURLSchemes"];
				deepLinkScheme = urlSchemes.firstObject;
				break;
			}
		}
	}
	result(deepLinkScheme);
}

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

			[_navigationViewController setNeedsUpdateOfSupportedInterfaceOrientationsIfPossible];

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

- (void)setNeedsUpdateOfSupportedInterfaceOrientationsIfPossible {
	if ([self respondsToSelector:@selector(setNeedsUpdateOfSupportedInterfaceOrientations)]) {
		if (@available(iOS 16.0, *)) {
			[self setNeedsUpdateOfSupportedInterfaceOrientations];
		}
	}
}


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
// LaunchScreenView

@interface LaunchScreenView()
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIActivityIndicatorView *activityView;
@property (nonatomic) UILabel *statusView;
@end

@implementation LaunchScreenView

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_imageView = [[UIImageView alloc] initWithFrame:frame];
		_imageView.image = [UIImage imageNamed:@"LaunchImage"];
		[self addSubview:_imageView];
		
		_activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[self addSubview:_activityView];
		
		_statusView = [[UILabel alloc] initWithFrame:CGRectZero];
		_statusView.font = [UIFont systemFontOfSize:16];
		_statusView.textAlignment = NSTextAlignmentCenter;
		_statusView.textColor = UIColor.whiteColor;
		_statusView.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
		_statusView.shadowOffset = CGSizeMake(1, 1);
		[self addSubview:_statusView];

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
	CGFloat activityY = (contentSize.height * 0.55) + ((contentSize.height * 0.30) - activitySize.height) / 2;
	_activityView.frame = CGRectMake((contentSize.width - activitySize.width) / 2, activityY, activitySize.width, activitySize.height);
	
	CGFloat statusPaddingX = 16;
	CGSize statusSize = [_statusView inaTextSizeForBoundWidth:contentSize.width - 2 * statusPaddingX];
	CGFloat statusY = (contentSize.height * 0.90) + ((contentSize.height * 0.10) - statusSize.height) / 2;
	_statusView.frame = CGRectMake(statusPaddingX, statusY, contentSize.width - 2 * statusPaddingX, statusSize.height);
}

- (NSString*)statusText {
	return _statusView.text;
}

- (void)setStatusText:(NSString*)value {
	_statusView.text = value;
	[self setNeedsLayout];
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

