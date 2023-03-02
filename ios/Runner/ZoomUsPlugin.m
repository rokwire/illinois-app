////  ZoomUsPlugin.m
//  Runner
//
//  Created by Mihail Varbanov on 01.03.23.
//  Copyright 2023 Board of Trustees of the University of Illinois.
	
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

#import "ZoomUsPlugin.h"
#import <MobileRTC/MobileRTC.h>

#import "NSDictionary+InaTypedValue.h"
#import "NSDate+InaUtils.h"

static NSString *const kZoomUsMethodChannel = @"edu.illinois.rokwire/zoom_us";

@interface ZoomUsPlugin()<MobileRTCAuthDelegate>
@property (nonatomic, strong) FlutterMethodChannel* channel;
@property (nonatomic, strong) MobileRTC* mobileRTC;

@end

///////////////////////////////////////////
// ZoomUsPlugin

@implementation ZoomUsPlugin

+ (instancetype)sharedInstance {
	static ZoomUsPlugin *_sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[self alloc] init];
	});

	return _sharedInstance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar{
	ZoomUsPlugin *instance = self.sharedInstance;
	instance.channel = [FlutterMethodChannel methodChannelWithName:kZoomUsMethodChannel binaryMessenger:registrar.messenger];
	[registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
	if (self = [super init]) {
		_mobileRTC = [MobileRTC sharedRTC];
	}
	return self;
}

#pragma mark SDK Initialization

- (void)initializeWithKeys:(NSDictionary*)keys {
	NSString *clientId = [keys inaStringForKey:@"client_id"];
	NSString *clientSecret = [keys inaStringForKey:@"client_secret"];
	NSString *domain = [keys inaStringForKey:@"domain"];
	
	MobileRTCSDKInitContext *context = [[MobileRTCSDKInitContext alloc] init];
	context.domain = domain;
	context.enableLog = YES;
	context.locale = MobileRTC_ZoomLocale_Default;
	BOOL initializeResult = [_mobileRTC initialize:context];
	NSLog(@"MobileRTC initialize => %@", initializeResult ? @"success" : @"fail");

	UINavigationController *navController = UIApplication.sharedApplication.keyWindow.rootViewController;
	if ([navController isKindOfClass:[UINavigationController class]]) {
		[_mobileRTC setMobileRTCRootController:navController];
	}

	MobileRTCAuthService *authService = [_mobileRTC getAuthService];
	if (authService != nil) {
		authService.delegate = self;
		authService.clientKey = clientId;
		authService.clientSecret = clientSecret;
		[authService sdkAuth];
	}
}

#pragma mark MethodCall

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
	if ([call.method isEqualToString:@"test"]) {
		result(@"works");
	}
}

// Implementation

// MobileRTCAuthDelegate




@end
