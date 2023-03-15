////  MobileAccessPlugin.m
//  Runner
//
//  Created by Dobromir Dobrev on 24.02.23.
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

#import "MobileAccessPlugin.h"

#import "NSDictionary+InaTypedValue.h"
#import "NSDate+InaUtils.h"

#import <OrigoSDK/OrigoSDK.h>

static NSString *const kMobileAccessMethodChannel = @"edu.illinois.rokwire/mobile_access";

static NSString *const kMobileAccessErrorDomain = @"edu.illinois.rokwire.mobile_access";

@interface MobileAccessPlugin()<OrigoKeysManagerDelegate>
@property (nonatomic, strong) FlutterMethodChannel* channel;

@property (nonatomic, strong) OrigoKeysManager* origoKeysManager;

@property (nonatomic, strong) NSMutableSet* startCompletions;
@property (nonatomic, assign) bool isStarted;

@property (nonatomic, strong) void (^registerEndpointCompletion)(NSError* error);
@property (nonatomic, strong) void (^unregisterEndpointCompletion)(NSError* error);
@end

@interface OrigoKeysKey(UIUC)
@property (nonatomic, readonly) NSDictionary* uiucJson;
@end

typedef NS_ENUM(NSInteger, MobileAccessError) {
	MobileAccessError_InitializeFailed = 1,
	MobileAccessError_NotInitialized,

	MobileAccessError_EndpoingAlreadySetup,
	MobileAccessError_EndpoingBeingSetup,

	MobileAccessError_EndpoingNotSetup,
	MobileAccessError_EndpoingBeingUnregister,
};



///////////////////////////////////////////
// MobileAccessPlugin

@implementation MobileAccessPlugin

+ (instancetype)sharedInstance {
    static MobileAccessPlugin *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
	
    return _sharedInstance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar{
	MobileAccessPlugin *instance = self.sharedInstance;
	instance.channel = [FlutterMethodChannel methodChannelWithName:kMobileAccessMethodChannel binaryMessenger:registrar.messenger];
	[registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
	if (self = [super init]) {
	}
	return self;
}

#pragma mark MethodCall

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
	if ([call.method isEqualToString:@"availableKeys"]) {
		result(self.mobileKeys);
	}
	else if ([call.method isEqualToString:@"registerEndpoint"]) {
		NSString* invitationCode = [call.arguments isKindOfClass:[NSString class]] ? call.arguments : nil;
		[self registerEndpointWithInvitationCode:invitationCode completion:^(NSError *error) {
			result([NSNumber numberWithBool:(error == nil)]);
		}];
	}
	else if ([call.method isEqualToString:@"unregisterEndpoint"]) {
		[self unregisterEndpointWithCompletion:^(NSError *error) {
			result([NSNumber numberWithBool:(error == nil)]);
		}];
	}
	else if ([call.method isEqualToString:@"isEndpointRegistered"]) {
		result([NSNumber numberWithBool:self.isEndpointRegistered]);
	}
    else if ([call.method isEqualToString:@"setRssiSensitivity"]) {
        //TBD: implement
        result([NSNumber numberWithBool:false]);
    }
}

// Implementation


- (void)startWithAppId:(NSString*)appId {
	[self startWithAppId:appId completion:nil];
}

- (void)startWithAppId:(NSString*)appId completion:(void (^)(NSError* error))completion {

	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *version = [NSString stringWithFormat:@"%@-%@ (%@)", appId,
		[bundleInfo inaStringForKey:@"CFBundleShortVersionString"],
		[bundleInfo inaStringForKey:@"CFBundleVersion"]
	];
	
	@try {
		_origoKeysManager = [[OrigoKeysManager alloc] initWithDelegate:self options:@{
			OrigoKeysOptionApplicationId: appId,
			OrigoKeysOptionVersion: version,
			OrigoKeysOptionSuppressApplePay: [NSNumber numberWithBool:TRUE],
		//OrigoKeysOptionBeaconUUID: @"...",
		}];
	}
	@catch (NSException *exception) {
		NSLog(@"Failed to initialize OrigoKeysManager: %@", exception);
	}

	if (_origoKeysManager == nil) {
		if (completion != nil) {
			completion([NSError errorWithDomain:kMobileAccessErrorDomain code: MobileAccessError_InitializeFailed userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo Controller not initialized.", nil) }]);
		}
	}
	else if (_isStarted) {
		completion(nil);
	}
	else if (_startCompletions != nil) {
		if (completion != nil) {
			[_startCompletions addObject:completion];
		}
	}
	else {
		_startCompletions = [[NSMutableSet alloc] init];
		if (completion != nil) {
			[_startCompletions addObject:completion];
		}
		[_origoKeysManager startup];
	}
}

- (void)didStartupWithError:(NSError*)error {
	_isStarted = (error == nil);

	if (_startCompletions != nil) {
		NSSet *startCompletions = _startCompletions;
		_startCompletions = nil;
		for (void (^completion)(NSError* error) in startCompletions) {
			completion(error);
		}
	}
}

- (NSArray*)mobileKeys {
	NSMutableArray* result = nil;
	if ([_origoKeysManager isEndpointSetup: NULL]) {
		NSArray<OrigoKeysKey*>* oregoKeys = [_origoKeysManager listMobileKeys: NULL];
		if (oregoKeys != nil) {
			result = [[NSMutableArray alloc] init];
			for (OrigoKeysKey* oregoKey in oregoKeys) {
				[result addObject:oregoKey.uiucJson];
			}
		}
	}
	return result;
}

- (bool)isEndpointRegistered {
	return (_origoKeysManager != nil) && _isStarted && [_origoKeysManager isEndpointSetup:NULL];
}

- (void)registerEndpointWithInvitationCode:(NSString*)invitationCode completion:(void (^)(NSError* error))completion {
	NSError *errorResult = nil;
	if ((_origoKeysManager == nil) || !_isStarted) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_NotInitialized userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo Controller not initialized.", nil) }];
	}
	else if ([_origoKeysManager isEndpointSetup:NULL]) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingAlreadySetup userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint already setup", nil) }];
	}
	else if (_registerEndpointCompletion != nil) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingBeingSetup userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint currently setup", nil) }];
	}
	else {
		_registerEndpointCompletion = completion;
		[_origoKeysManager setupEndpoint:invitationCode];
	}

	if ((errorResult != nil) && (completion != nil)) {
		completion(errorResult);
	}
}

- (void)didRegisterEndpointWithError:(NSError*)error {
	if (_registerEndpointCompletion != nil) {
		void (^ completion)(NSError* error) = _registerEndpointCompletion;
		_registerEndpointCompletion = nil;
		completion(error);
	}
}

- (void)unregisterEndpointWithCompletion:(void (^)(NSError* error))completion {
	NSError *errorResult = nil;
	if ((_origoKeysManager == nil) || !_isStarted) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_NotInitialized userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo Controller not initialized.", nil) }];
	}
	else if (![_origoKeysManager isEndpointSetup:NULL]) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingNotSetup userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint not setup", nil) }];
	}
	else if (_unregisterEndpointCompletion != nil) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingBeingUnregister userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint currently unregister", nil) }];
	}
	else {
		_unregisterEndpointCompletion = completion;
		[_origoKeysManager unregisterEndpoint];
	}

	if ((errorResult != nil) && (completion != nil)) {
		completion(errorResult);
	}
}

- (void)didUnregisterEndpointWithError:(NSError*)error {
	if (_unregisterEndpointCompletion != nil) {
		void (^ completion)(NSError* error) = _unregisterEndpointCompletion;
		_unregisterEndpointCompletion = nil;
		completion(error);
	}
}

#pragma mark OrigoKeysManagerDelegate

- (void)origoKeysDidStartup {
	[self didStartupWithError:nil];
}

- (void)origoKeysDidFailToStartup:(NSError *)error {
	[self didStartupWithError:error];
}

- (void)origoKeysDidSetupEndpoint {
	[self didRegisterEndpointWithError:nil];
}

- (void)origoKeysDidFailToSetupEndpoint:(NSError *)error {
	[self didRegisterEndpointWithError:error];
}

- (void)origoKeysDidUpdateEndpoint {}
- (void)origoKeysDidUpdateEndpointWithSummary:(OrigoKeysEndpointUpdateSummary *)endpointUpdateSummary {}
- (void)origoKeysDidFailToUpdateEndpoint:(NSError *)error {}

- (void)origoKeysDidTerminateEndpoint {
	[self didUnregisterEndpointWithError:nil];
}

@end

///////////////////////////////////////////
// OrigoKeysKey+UIUC

@implementation OrigoKeysKey(UIUC)

- (NSDictionary*)uiucJson {
	return @{
		@"type": self.keyType ?: [NSNull null],
		@"card_number": self.cardNumber ?: [NSNull null],
		@"active": [NSNumber numberWithBool:self.active],
		@"key_identifier": self.keyId ?: [NSNull null],
		@"unique_identifier": self.uniqueIdentifier ?: [NSNull null],
		@"external_id": self.externalId ?: [NSNull null],

		@"name": self.name ?: [NSNull null],
		@"suffix": self.suffix ?: [NSNull null],
		@"access_token": self.accessToken ?: [NSNull null],

		@"label": self.label ?: [NSNull null],
		@"issuer": self.issuer ?: [NSNull null],
		
		@"begin_date": [self.beginDate inaStringWithFormat:@"yyyy-MM-dd"] ?: [NSNull null],
		@"expiration_date": [self.endDate inaStringWithFormat:@"yyyy-MM-dd"] ?: [NSNull null],
	};
}

@end
