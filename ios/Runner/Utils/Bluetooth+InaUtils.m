//
//  CBPeripheral+InaUtils.m
//  Runner
//
//  Created by Mladen Dryankov on 16.12.19.
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

#import "Bluetooth+InaUtils.h"
#import "NSDictionary+InaTypedValue.h"

//////////////////////////////////////
// InaBluetooth

@implementation InaBluetooth

+ (InaBluetoothAuthorizationStatus)peripheralAuthorizationStatus {
	if (@available(iOS 13.1, *)) {
		switch(CBPeripheralManager.authorization) {
			case CBManagerAuthorizationNotDetermined:                 return InaBluetoothAuthorizationStatusNotDetermined;
			case CBManagerAuthorizationRestricted:                    return InaBluetoothAuthorizationStatusRestricted;
			case CBManagerAuthorizationDenied:                        return InaBluetoothAuthorizationStatusDenied;
			case CBManagerAuthorizationAllowedAlways:                 return InaBluetoothAuthorizationStatusAuthorized;
		}
	} else {
		switch (CBPeripheralManager.authorizationStatus) {
			case CBPeripheralManagerAuthorizationStatusNotDetermined: return InaBluetoothAuthorizationStatusNotDetermined;
			case CBPeripheralManagerAuthorizationStatusRestricted:    return InaBluetoothAuthorizationStatusRestricted;
			case CBPeripheralManagerAuthorizationStatusDenied:        return InaBluetoothAuthorizationStatusDenied;
			case CBPeripheralManagerAuthorizationStatusAuthorized:    return InaBluetoothAuthorizationStatusAuthorized;
		}
	}
}

+ (InaBluetoothAuthorizationStatus)centralAuthorizationStatus {
	if (@available(iOS 13.1, *)) {
		switch(CBCentralManager.authorization) {
			case CBManagerAuthorizationNotDetermined:                 return InaBluetoothAuthorizationStatusNotDetermined;
			case CBManagerAuthorizationRestricted:                    return InaBluetoothAuthorizationStatusRestricted;
			case CBManagerAuthorizationDenied:                        return InaBluetoothAuthorizationStatusDenied;
			case CBManagerAuthorizationAllowedAlways:                 return InaBluetoothAuthorizationStatusAuthorized;
		}
	} else {
		return InaBluetoothAuthorizationStatusAuthorized;
	}
}

@end

//////////////////////////////////////
// InaBluetoothAuthorizationStatus

NSString* InaBluetoothAuthorizationStatusToString(InaBluetoothAuthorizationStatus value) {
	switch (value) {
		case InaBluetoothAuthorizationStatusNotDetermined: return @"not_determined";
		case InaBluetoothAuthorizationStatusRestricted:    return @"not_supported";
		case InaBluetoothAuthorizationStatusDenied:        return @"denied";
		case InaBluetoothAuthorizationStatusAuthorized:    return @"allowed";
	}
}

InaBluetoothAuthorizationStatus InaBluetoothAuthorizationStatusFromString(NSString *value) {
	if ([value isEqualToString:@"not_determined"]) {
		return InaBluetoothAuthorizationStatusNotDetermined;
	}
	else if ([value isEqualToString:@"not_supported"]) {
		return InaBluetoothAuthorizationStatusRestricted;
	}
	else if ([value isEqualToString:@"denied"]) {
		return InaBluetoothAuthorizationStatusDenied;
	}
	else if ([value isEqualToString:@"allowed"]) {
		return InaBluetoothAuthorizationStatusAuthorized;
	}
	else {
		return InaBluetoothAuthorizationStatusNotDetermined;
	}
}

//////////////////////////////////////
// CBPeripheral+InaUtils

@implementation CBPeripheral(InaUtils)

- (CBService*)inaServiceWithUUID:(CBUUID*)uuid {
	for (CBService *service in self.services) {
		if([uuid isEqual: service.UUID]){
			return service;
		}
	}
	return nil;
}

@end

//////////////////////////////////////
// CBService+InaUtils

@implementation CBService(InaUtils)

- (CBCharacteristic*)inaCharacteristicWithUUID:(CBUUID *)uuid {
	for(CBCharacteristic *characteristic in self.characteristics){
		if([characteristic.UUID isEqual:uuid]) {
			return characteristic;
		}
	}
	return nil;
}

- (CBMutableCharacteristic*)inaMutableCharacteristicWithUUID:(CBUUID*)uuid; {
	CBCharacteristic *characteristic = [self inaCharacteristicWithUUID:uuid];
	return [characteristic isKindOfClass:[CBMutableCharacteristic class]] ? ((CBMutableCharacteristic*)characteristic) : nil;
}

@end

//////////////////////////////////////
// NSDictionary+InaBluetoothUtils

@implementation NSDictionary(InaBluetoothUtils)

- (bool)inaAdvertisementDataContainsServiceWithUuid:(CBUUID*)serviceUuid {
	NSArray *serviceUuids = [self inaArrayForKey:CBAdvertisementDataServiceUUIDsKey];
	for (CBUUID *peripheralServiceUuid in serviceUuids) {
		if ([peripheralServiceUuid isEqual:serviceUuid]) {
			return true;
		}
	}

	serviceUuids = [self inaArrayForKey: CBAdvertisementDataOverflowServiceUUIDsKey];
	for (CBUUID *peripheralServiceUuid in serviceUuids) {
		if ([peripheralServiceUuid isEqual:serviceUuid]) {
			return true;
		}
	}
	
	return false;
}

@end
