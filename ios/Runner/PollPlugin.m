//
//  PollServer.m
//  Runner
//
//  Created by Mladen Dryankov on 13.12.19.
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

#import "PollPlugin.h"
#import "AppDelegate.h"
#import "NSDictionary+InaTypedValue.h"
#import "NSString+InaJson.h"
#import "NSData+InaHex.h"
#import "Bluetooth+InaUtils.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <UserNotifications/UserNotifications.h>

// Channel Commands
static NSString* const ChannelStartScan	 							= @"start_scan";
static NSString* const ChannelStopScan	 							= @"stop_scan";
static NSString* const ChannelCreatePoll	 						= @"create_poll";

static NSString* const ChannelEnable		 						= @"enable";
static NSString* const ChannelDisable		 						= @"disable";

// Notification
static NSString* const ChannelOnPollCreated	 						= @"on_poll_created";

// Periphere Name
static NSString* const PollPluginPeriphereName		 				= @"Poll";

@interface PollPlugin()<CBPeripheralManagerDelegate, CBCentralManagerDelegate>{
	bool 					initialized;
	
	FlutterMethodChannel	*channel;
	
	CBCentralManager		*centralManager;
	CBPeripheralManager		*peripheralManager;
	
	NSMutableSet			*processedPollIds;
	
	NSTimer					*timoutTimer;
}
@property(nonatomic,assign,readonly) bool 		isAuthorized;
@end

@implementation PollPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar{
	FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"edu.illinois.rokwire/polls" binaryMessenger:registrar.messenger];
	PollPlugin *instance = [[PollPlugin alloc] initWithChannel:channel];
	[registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init
{
	if (self = [super init]) {
		processedPollIds = [NSMutableSet new];
	}
	return self;
}

- (instancetype)initWithChannel:(FlutterMethodChannel*)_channel
{
	if (self = [self init]) {
		channel = _channel;
	}
	return self;
}

-(void)initialize{
	if(self.isAuthorized && !initialized){
		peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
		centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{
			CBCentralManagerOptionShowPowerAlertKey : [NSNumber numberWithBool:NO],
		}];
		
		initialized = true;
	}
}

-(void)deinitialize{
	if(initialized){
		[self stopScan];
		peripheralManager.delegate = nil;
		peripheralManager = nil;
		centralManager.delegate = nil;
		centralManager = nil;
		initialized = false;
	}
}

-(bool)isAuthorized{
	return (InaBluetooth.peripheralAuthorizationStatus == InaBluetoothAuthorizationStatusAuthorized) && (InaBluetooth.centralAuthorizationStatus == InaBluetoothAuthorizationStatusAuthorized);
}

//////////////
// Server Side

- (void)startWithPollId:(NSString*)_pollId{
	[self initialize];
	
	// Dont start server if it's not preperly initialized
	if(!initialized || !self.isAuthorized){
		NSLog(@"Poll service is not properly setup, initialized or authorized");
		return;
	}
	
	CBUUID *pollUuid = [self cbUuidFromString:_pollId];

	if(peripheralManager.isAdvertising){
		[peripheralManager stopAdvertising];
	}
	
	if(pollUuid != nil){
		[peripheralManager startAdvertising:
			@{ CBAdvertisementDataServiceUUIDsKey :@[pollUuid],
			   CBAdvertisementDataLocalNameKey:PollPluginPeriphereName
		}];
		[self startTimoutTimer];
	}
}

- (void)stop{
	
	// Dont stop server if it's not preperly initialized at the beginning
	if(!initialized){
		NSLog(@"Poll service is not properly setup && initialized");
		return;
	}
	[self stopTimeoutTimer];
	[peripheralManager stopAdvertising];
}

#pragma mark CBPeripheralManager

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
	NSLog(@"CBPeripheralManager State: %@",@(peripheral.state));
}

-(void)startTimoutTimer{
	[self stopTimeoutTimer];
	timoutTimer = [NSTimer scheduledTimerWithTimeInterval:5*60 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self stop];
	}];
}

-(void)stopTimeoutTimer{
	if(timoutTimer != nil){
		[timoutTimer invalidate];
		timoutTimer = nil;
	}
}

//////////////
// Client Side

-(void)startScan{
	if (centralManager.state == CBManagerStatePoweredOn) {
		[centralManager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
	}
}

-(void)stopScan{
	[centralManager stopScan];
}

#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
	if (centralManager.state == CBManagerStatePoweredOn) {
		[self startScan];
	}
	else{
		[self stopScan];
	}
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
	
	// With this we ensure it's a valid UUID otherwise ignore
	NSString *periphereName = [advertisementData inaStringForKey:CBAdvertisementDataLocalNameKey];
	NSArray *serviceUuids = [advertisementData inaArrayForKey:CBAdvertisementDataServiceUUIDsKey];
	if([PollPluginPeriphereName isEqualToString:periphereName] && serviceUuids.count > 0){
		NSString *convertedId = [self pollIdFromCbUuid:serviceUuids.firstObject];
		
		if(![processedPollIds containsObject:convertedId]){
			[channel invokeMethod:ChannelOnPollCreated arguments:convertedId];
			[processedPollIds addObject:convertedId];
		}
	}
	
}

#pragma mark Utils

- (NSString*) pollIdFromCbUuid:(CBUUID*)uuid{
	if(uuid != nil){
		NSData *uuidData = [uuid data];
		NSData *convertedData = uuidData.length >= 12 ? [uuidData subdataWithRange:NSMakeRange(0, 12)] : nil;
		NSString *convertedId = [convertedData inaHexString];
		return convertedId;
	}
	return nil;
}

- (CBUUID*) cbUuidFromString:(NSString*)string{
	if(string != nil){
		NSMutableData *pollIdData = [NSMutableData dataWithData:string.inaDataFromHex];
		if(pollIdData.length < 16){
			[pollIdData increaseLengthBy:(16 - pollIdData.length)];
			return [CBUUID UUIDWithData:pollIdData];
		}
		else{
			return [CBUUID UUIDWithData:[pollIdData subdataWithRange:NSMakeRange(0, 16)]];
		}
	}
	return nil;
}

#pragma mark MethodCall

-(void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
	if([ChannelStartScan isEqualToString:call.method]){
		[self startScan];
	}
	else if([ChannelStopScan isEqualToString:call.method]){
		[self stopScan];
	}
	else if([ChannelCreatePoll isEqualToString:call.method]){
		if([call.arguments isKindOfClass:NSString.class]){
			NSString *value = (NSString*) call.arguments;
			if(value.length > 0){
				[self startWithPollId:value];
			}
		}
	}
	else if([ChannelEnable isEqualToString:call.method]){
		[self initialize];
	}
	else if([ChannelDisable isEqualToString:call.method]){
		[self deinitialize];
	}
	result(nil);
}
@end
