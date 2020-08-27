//
//  CBPeripheral+InaUtils.h
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

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger, InaBluetoothAuthorizationStatus) {
	InaBluetoothAuthorizationStatusNotDetermined = 0,
	InaBluetoothAuthorizationStatusRestricted,
	InaBluetoothAuthorizationStatusDenied,
	InaBluetoothAuthorizationStatusAuthorized,
};

NSString* InaBluetoothAuthorizationStatusToString(InaBluetoothAuthorizationStatus value);
InaBluetoothAuthorizationStatus InaBluetoothAuthorizationStatusFromString(NSString *value);

@interface InaBluetooth : NSObject
@property(nonatomic, class, readonly) InaBluetoothAuthorizationStatus peripheralAuthorizationStatus;
@property(nonatomic, class, readonly) InaBluetoothAuthorizationStatus centralAuthorizationStatus;
@end

@interface CBPeripheral(InaUtils)
- (CBService*)inaServiceWithUUID:(CBUUID*)uuid;
@end

@interface CBService(InaUtils)
- (CBCharacteristic*)inaCharacteristicWithUUID:(CBUUID*)uuid;
- (CBMutableCharacteristic*)inaMutableCharacteristicWithUUID:(CBUUID*)uuid;
@end

@interface NSDictionary(InaBluetoothUtils)
- (bool)inaAdvertisementDataContainsServiceWithUuid:(CBUUID*)serviceUuid;
@end
