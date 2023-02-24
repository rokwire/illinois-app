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
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>

@interface MobileAccessPlugin()
@property (nonatomic, strong) FlutterMethodChannel* channel;
@end

@implementation MobileAccessPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar{
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"edu.illinois.rokwire/mobile_access" binaryMessenger:registrar.messenger];
    MobileAccessPlugin *instance = [[MobileAccessPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel*)_channel{
    if (self = [self init]) {
        channel = _channel;
    }
    return self;
}

#pragma mark MethodCall

-(void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    NSDictionary *parameters = [call.arguments isKindOfClass:[NSDictionary class]] ? call.arguments : nil;
    if ([call.method isEqualToString:@"availableKeys"]) {
        [self handleMobileAccessKeysWithParameters:parameters result:result];
    }
    else if ([call.method isEqualToString:@"registerEndpoint"]) {
        [self handleMobileAccessKeysRegisterEndpointWithArgument:call.arguments result:result];
    }
    else if ([call.method isEqualToString:@"unregisterEndpoint"]) {
        [self handleMobileAccessKeysUnregisterEndpointWithParameters:parameters result:result];
    }
    else if ([call.method isEqualToString:@"isEndpointRegistered"]) {
        [self handleMobileAccessKeysIsEndpointRegisteredWithParameters:parameters result:result];
    }
}

- (void)handleMobileAccessKeysWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
    //TBD: implement
    NSLog(@"Mobile Keys: not implemented 1")
    result(nil);
}

- (void)handleMobileAccessKeysRegisterEndpointWithArgument:(id)argument result:(FlutterResult)result {
    //TBD: implement
    NSLog(@"Mobile Keys: not implemented 2")
    result(nil);
}

- (void)handleMobileAccessKeysUnregisterEndpointWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
    //TBD: implement
    NSLog(@"Mobile Keys: not implemented 3")
    result(nil);
}

- (void)handleMobileAccessKeysIsEndpointRegisteredWithParameters:(NSDictionary*)parameters result:(FlutterResult)result {
    //TBD: implement
    NSLog(@"Mobile Keys: not implemented 4")
    result(nil);
}

@end
