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
#import "NSUserDefaults+InaUtils.h"

#import <OrigoSDK/OrigoSDK.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioServices.h>

static NSString *const kMobileAccessMethodChannel = @"edu.illinois.rokwire/mobile_access";

static NSString *const kMobileAccessErrorDomain = @"edu.illinois.rokwire.mobile_access";

static const int LOCK_SERVICE_CODE_AAMK = 1;
static const int LOCK_SERVICE_CODE_HID = 2;

static NSString *const kPreviouslyLaunchedKey = @"edu.illinois.rokwire.mobile_access.previously_launched";
static NSString *const kSupportedOpeningTypesKey = @"edu.illinois.rokwire.mobile_access.opeining_types";
static NSString *const kLockServiceCodesKey = @"edu.illinois.rokwire.mobile_access.lock_service_codes";
static NSString *const kUnlockVibrationKey = @"edu.illinois.rokwire.mobile_access.unlock.vibration";
static NSString *const kUnlockSoundKey = @"edu.illinois.rokwire.mobile_access.unlock.sound";


@interface MobileAccessPlugin()<OrigoKeysManagerDelegate> {
  bool _scanAllowed;
}
@property (nonatomic, strong) FlutterMethodChannel* channel;

@property (nonatomic, strong) OrigoKeysManager* origoKeysManager;
@property (nonatomic, retain) NSMutableSet<NSNumber*>* supportedOpeningTypes;
@property (nonatomic, retain) NSArray<NSNumber*>* lockServiceCodes;

@property (nonatomic, strong) NSMutableSet* startCompletions;
@property (nonatomic, assign) bool isStarted;

@property (nonatomic, strong) void (^registerEndpointCompletion)(NSError* error);
@property (nonatomic, strong) void (^unregisterEndpointCompletion)(NSError* error);
@property (nonatomic, strong) void (^updateEndpointCompletion)(NSError* error);

@property (nonatomic, assign) SystemSoundID soundId;
@end

@interface OrigoKeysKey(UIUC)
@property (nonatomic, readonly) NSDictionary* uiucJson;
@end

typedef NS_ENUM(NSInteger, MobileAccessError) {
	MobileAccessError_NotAvailable = 1,
	MobileAccessError_InitializeSkipped,
	MobileAccessError_InitializeFailed,
	MobileAccessError_NotInitialized,

	MobileAccessError_EndpoingAlreadySetup,
	MobileAccessError_EndpoingBeingSetup,

	MobileAccessError_EndpoingNotSetup,
	MobileAccessError_EndpoingBeingUnregister,
	MobileAccessError_EndpoingBeingUpdated,
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

		NSURL* audioUrl = [[NSBundle mainBundle] URLForResource:@"hid-unlock" withExtension:@"wav"];
		if (audioUrl != nil) {
			AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioUrl, &_soundId);
		}
		
		NSArray<NSNumber*>* supportedOpenningTypes = [[NSUserDefaults standardUserDefaults] objectForKey:kSupportedOpeningTypesKey] ?: self.class.defaultOpeningTypes;
		_supportedOpeningTypes = [NSMutableSet<NSNumber*> setWithArray:supportedOpenningTypes];
		
		_lockServiceCodes = [[NSUserDefaults standardUserDefaults] objectForKey:kLockServiceCodesKey] ?: self.class.defaultLockServiceCodes;
	}
	return self;
}

#pragma mark MethodCall

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
	if ([call.method isEqualToString:@"start"]) {
		__weak typeof(self) weakSelf = self;
		NSNumber* value = [call.arguments isKindOfClass:[NSNumber class]] ? call.arguments : nil;
		[self startForced:value.boolValue completion:^(NSError *error) {
			NSNumber *resultValue = [NSNumber numberWithBool:(error == nil)];
			result(resultValue);
			[weakSelf.channel invokeMethod:@"start.finished" arguments:resultValue];
		}];
	}
	else if ([call.method isEqualToString:@"availableKeys"]) {
		result(self.mobileKeys);
	}
	else if ([call.method isEqualToString:@"registerEndpoint"]) {
		__weak typeof(self) weakSelf = self;
		NSString* invitationCode = [call.arguments isKindOfClass:[NSString class]] ? call.arguments : nil;
		[self registerEndpointWithInvitationCode:invitationCode completion:^(NSError *error) {
			NSNumber *resultValue = [NSNumber numberWithBool:(error == nil)];
			result(resultValue);
			[weakSelf.channel invokeMethod:@"endpoint.register.finished" arguments:resultValue];
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
	else if ([call.method isEqualToString:@"allowScanning"]) {
		NSNumber* value = [call.arguments isKindOfClass:[NSNumber class]] ? call.arguments : nil;
		if (value != nil) {
			self.scanAllowed = [value boolValue];
		}
		result([NSNumber numberWithBool:(value != nil)]);
	}
	else if ([call.method isEqualToString:@"setRssiSensitivity"]) {
		// Not available in iOS
		result([NSNumber numberWithBool:false]);
	}
	else if ([call.method isEqualToString:@"getLockServiceCodes"]) {
		result(_lockServiceCodes);
	}
	else if ([call.method isEqualToString:@"setLockServiceCodes"]) {
		NSArray* value = [call.arguments isKindOfClass:[NSArray class]] ? call.arguments : nil;
		if (value != nil) {
			[[NSUserDefaults standardUserDefaults] setObject:(_lockServiceCodes = value) forKey:kLockServiceCodesKey];
		}
		result([NSNumber numberWithBool:(value != nil)]);
	}
	else if ([call.method isEqualToString:@"isTwistAndGoEnabled"]) {
		result([NSNumber numberWithBool:self.twistAndGoEnabled]);
	}
	else if ([call.method isEqualToString:@"enableTwistAndGo"]) {
		NSNumber* value = [call.arguments isKindOfClass:[NSNumber class]] ? call.arguments : nil;
		if (value != nil) {
			self.twistAndGoEnabled = [value boolValue];
		}
		result([NSNumber numberWithBool:(value != nil)]);
	}
	else if ([call.method isEqualToString:@"isUnlockVibrationEnabled"]) {
		result([NSNumber numberWithBool:self.unlockVibrationEnabled]);
	}
	else if ([call.method isEqualToString:@"enableUnlockVibration"]) {
		NSNumber* value = [call.arguments isKindOfClass:[NSNumber class]] ? call.arguments : nil;
		if (value != nil) {
			self.unlockVibrationEnabled = value.boolValue;
		}
		result([NSNumber numberWithBool:(value != nil)]);
	}
	else if ([call.method isEqualToString:@"isUnlockSoundEnabled"]) {
		result([NSNumber numberWithBool:self.unlockSoundEnabled]);
	}
	else if ([call.method isEqualToString:@"enableUnlockSound"]) {
		NSNumber* value = [call.arguments isKindOfClass:[NSNumber class]] ? call.arguments : nil;
		if (value != nil) {
			self.unlockSoundEnabled = value.boolValue;
		}
		result([NSNumber numberWithBool:(value != nil)]);
	}
}

// Implementation

- (void)startForced:(bool)forced completion:(void (^)(NSError* error))completion {
	if (forced || [[NSUserDefaults standardUserDefaults] inaBoolForKey:kPreviouslyLaunchedKey]) {
		[self _startWithCompletion:completion];
	}
	else if (completion != nil) {
		completion([NSError errorWithDomain:kMobileAccessErrorDomain code: MobileAccessError_InitializeSkipped userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Initialize skipped.", nil) }]);
	}
}

- (void)_startWithCompletion:(void (^)(NSError* error))completion {
	if (0 < _origoAppId.length) {
	
		if (_origoKeysManager == nil) {
			NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
			NSString *version = [NSString stringWithFormat:@"%@-%@ (%@)", _origoAppId,
				[bundleInfo inaStringForKey:@"CFBundleShortVersionString"],
				[bundleInfo inaStringForKey:@"CFBundleVersion"]
			];
			
			@try {
				_origoKeysManager = [[OrigoKeysManager alloc] initWithDelegate:self options:@{
					OrigoKeysOptionApplicationId: _origoAppId,
					OrigoKeysOptionVersion: version,
					OrigoKeysOptionSuppressApplePay: [NSNumber numberWithBool:TRUE],
				//OrigoKeysOptionBeaconUUID: @"...",
				}];
			}
			@catch (NSException *exception) {
				NSLog(@"Failed to initialize OrigoKeysManager: %@", exception);
			}
		}

		if (_origoKeysManager == nil) {
			if (completion != nil) {
				completion([NSError errorWithDomain:kMobileAccessErrorDomain code: MobileAccessError_InitializeFailed userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo Controller not initialized.", nil) }]);
			}
		}
		else if (_isStarted) {
			if (completion != nil) {
				completion(nil);
			}
		}
		else if (_startCompletions != nil) {
			if (completion != nil) {
				[_startCompletions addObject:completion];
			}
		}
		else {
			[[NSUserDefaults standardUserDefaults] inaSetBool: true forKey:kPreviouslyLaunchedKey];

			_startCompletions = [[NSMutableSet alloc] init];
			if (completion != nil) {
				[_startCompletions addObject:completion];
			}
			
			[_origoKeysManager startup];
		}
	}
	else if (completion != nil) {
		completion([NSError errorWithDomain:kMobileAccessErrorDomain code: MobileAccessError_NotAvailable userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo App Id not available.", nil) }]);
	}
}

- (void)didStartupWithError:(NSError*)error {
	_isStarted = (error == nil);
	if (_isStarted) {
		[_origoKeysManager setSupportedOpeningTypes:_supportedOpeningTypes.allObjects];
		
		if (self.isEndpointSetup) {
			[self updateEndpointWithCompletion:^(NSError *error) {
			}];
		}
	}
	[self notifyStartupCompleteWithError: error];
}

- (void)notifyStartupCompleteWithError:(NSError*)error {
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
	if (self.isEndpointSetup) {
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
	return (_origoKeysManager != nil) && _isStarted && self.isEndpointSetup;
}

- (void)registerEndpointWithInvitationCode:(NSString*)invitationCode completion:(void (^)(NSError* error))completion {
	NSError *errorResult = nil;
	if ((_origoKeysManager == nil) || !_isStarted) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_NotInitialized userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo Controller not initialized.", nil) }];
	}
	//else if (self.isEndpointSetup) {
	//	errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingAlreadySetup userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint already setup", nil) }];
	//}
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
	else if (!self.isEndpointSetup) {
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

- (void)updateEndpointWithCompletion:(void (^)(NSError* error))completion {
	NSError *errorResult = nil;
	if ((_origoKeysManager == nil) || !_isStarted) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_NotInitialized userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Origo Controller not initialized.", nil) }];
	}
	else if (!self.isEndpointSetup) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingNotSetup userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint not setup", nil) }];
	}
	else if (_updateEndpointCompletion != nil) {
		errorResult = [NSError errorWithDomain:kMobileAccessErrorDomain code:MobileAccessError_EndpoingBeingUpdated userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Endpoint currently updated", nil) }];
	}
	else {
		_updateEndpointCompletion = completion;
		[_origoKeysManager updateEndpoint];
	}

	if ((errorResult != nil) && (completion != nil)) {
		completion(errorResult);
	}
}

- (void)didUpdateEndpointWithError:(NSError*)error {
	if (_updateEndpointCompletion != nil) {
		void (^ completion)(NSError* error) = _updateEndpointCompletion;
		_updateEndpointCompletion = nil;
		completion(error);
	}
}

- (bool)scanAllowed {
	return _scanAllowed;
}

- (void)setScanAllowed:(bool)scanAllowed {
	_scanAllowed = scanAllowed;

	if (self.canScan) {
		if (!self.isScanning) {
			[self startScan];
		}
	}
	else {
		if (self.isScanning) {
			[self stopScan];
		}
	}
}

- (bool)canScan {
	return _isStarted && _scanAllowed && self.isEndpointSetup && self.hasMobileKeys;
}

- (bool)isScanning {
	return [_origoKeysManager isScanning];
}

- (bool)isEndpointSetup {
	return [_origoKeysManager isEndpointSetup:NULL];
}

- (bool)hasMobileKeys {
	return [_origoKeysManager listMobileKeys: NULL].count > 0;
}

- (void)startScan {
	[_origoKeysManager startReaderScanInMode:OrigoKeysScanModeOptimizePowerConsumption supportedOpeningTypes:_supportedOpeningTypes.allObjects lockServiceCodes:_lockServiceCodes error:nil];
}

- (void)stopScan {
	[_origoKeysManager stopReaderScan];
}

- (void)notifyScanning:(bool)scanning {
	[self.channel invokeMethod:@"device.scanning" arguments:[NSNumber numberWithBool:scanning]];
}

+ (NSArray*)defaultLockServiceCodes {
	return @[
		[NSNumber numberWithInt:LOCK_SERVICE_CODE_AAMK],
		[NSNumber numberWithInt:LOCK_SERVICE_CODE_HID],
	];
}

- (bool)twistAndGoEnabled {
	return [_supportedOpeningTypes containsObject:@(OrigoKeysOpeningTypeMotion)];
}

- (void)setTwistAndGoEnabled:(bool)value {
	NSArray* supportedOpeningTypes = nil;
	if (value) {
		if (![_supportedOpeningTypes containsObject:@(OrigoKeysOpeningTypeMotion)]) {
			[_supportedOpeningTypes addObject:@(OrigoKeysOpeningTypeMotion)];
			supportedOpeningTypes = _supportedOpeningTypes.allObjects;
		}
	}
	else if ([_supportedOpeningTypes containsObject:@(OrigoKeysOpeningTypeMotion)]) {
		[_supportedOpeningTypes removeObject:@(OrigoKeysOpeningTypeMotion)];
		supportedOpeningTypes = _supportedOpeningTypes.allObjects;
	}

	if (supportedOpeningTypes != nil) {
		[_origoKeysManager setSupportedOpeningTypes:supportedOpeningTypes];
		[[NSUserDefaults standardUserDefaults] setObject:supportedOpeningTypes forKey:kSupportedOpeningTypesKey];
	}
}

- (bool)unlockVibrationEnabled {
	return [[NSUserDefaults standardUserDefaults] inaBoolForKey:kUnlockVibrationKey];
}

- (void)setUnlockVibrationEnabled:(bool)value {
	[[NSUserDefaults standardUserDefaults] inaSetBool:value forKey:kUnlockVibrationKey];
	if (value) {
		[self vibrate];
	}
}

- (bool)unlockSoundEnabled {
	return [[NSUserDefaults standardUserDefaults] inaBoolForKey:kUnlockSoundKey];
}

- (void)setUnlockSoundEnabled:(bool)value {
	[[NSUserDefaults standardUserDefaults] inaSetBool:value forKey:kUnlockSoundKey];
	if (value) {
		[self sound];
	}
}

// Helpers

+ (NSArray<NSNumber*>*)defaultOpeningTypes {
	return @[
		@(OrigoKeysOpeningTypeProximity),
		@(OrigoKeysOpeningTypeMotion),
		@(OrigoKeysOpeningTypeSeamless),
		@(OrigoKeysOpeningTypeApplicationSpecific),
		@(OrigoKeysOpeningTypeEnhancedTap)
	];
}


- (void)sound {
	if (_soundId != 0) {
		AudioServicesPlaySystemSound(_soundId);
	}
}

- (void)vibrate {
	[[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
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

- (void)origoKeysDidUpdateEndpoint {
	[self didUpdateEndpointWithError:nil];
}

- (void)origoKeysDidUpdateEndpointWithSummary:(OrigoKeysEndpointUpdateSummary *)endpointUpdateSummary {
	[self didUpdateEndpointWithError:nil];
}

- (void)origoKeysDidFailToUpdateEndpoint:(NSError *)error {
	[self didUpdateEndpointWithError:error];
}

- (void)origoKeysDidTerminateEndpoint {
	[self didUnregisterEndpointWithError:nil];
}

- (void)origoKeysDidConnectToReader:(OrigoKeysReader *)reader openingType:(OrigoKeysOpeningType)type {
	if ([[NSUserDefaults standardUserDefaults] inaBoolForKey:kUnlockVibrationKey]) {
		[self vibrate];
	}
	if ([[NSUserDefaults standardUserDefaults] inaBoolForKey:kUnlockSoundKey]) {
		[self sound];
	}
	[self notifyScanning:true];
}

- (void)origoKeysDidFailToConnectToReader:(OrigoKeysReader *)reader openingType:(OrigoKeysOpeningType)type openingStatus:(OrigoKeysOpeningStatusType)status {
	[self notifyScanning:false];
}

- (void)origoKeysDidDisconnectFromReader:(OrigoKeysReader *)reader openingType:(OrigoKeysOpeningType)type openingResult:(OrigoKeysOpeningResult *)result {
	[self notifyScanning:false];
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
