////  OrigoController.m
//  Runner
//
//  Created by Mihail Varbanov on 2/21/23.
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

#import "OrigoController.h"

#import "NSDictionary+InaTypedValue.h"

#import <OrigoSDK/OrigoSDK.h>

@interface OrigoController()<OrigoKeysManagerDelegate>
@property (nonatomic, strong) OrigoKeysManager*    origoKeysManager;
@property (nonatomic, strong) NSMutableSet* startCompletions;
@end

///////////////////////////////////////////
// OrigoController

@implementation OrigoController

+ (instancetype)sharedInstance {
    static OrigoController *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
	
    return _sharedInstance;
}

- (instancetype)init {
	if (self = [super init]) {
	}
	return self;
}

- (void)initializeWithAppId:(NSString*)appId {
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
}

- (void)start {
	[self startWithCompletion:nil];
}
- (void)startWithCompletion:(void (^)(NSError* error))completion {
	//NSError *error = NULL;
	//if ([_origoKeysManager isEndpointSetup:&error] != TRUE)

	if (_startCompletions != nil) {
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
	if (_startCompletions != nil) {
		NSSet *startCompletions = _startCompletions;
		_startCompletions = nil;
		for (void (^completion)(NSError* error) in startCompletions) {
			completion(error);
		}
	}
}

#pragma mark OrigoKeysManagerDelegate

- (void)origoKeysDidStartup {
	[self didStartupWithError:nil];
}

- (void)origoKeysDidFailToStartup:(NSError *)error {
	[self didStartupWithError:error];
}

- (void)origoKeysDidSetupEndpoint {}
- (void)origoKeysDidFailToSetupEndpoint:(NSError *)error {}

- (void)origoKeysDidUpdateEndpoint {}
- (void)origoKeysDidUpdateEndpointWithSummary:(OrigoKeysEndpointUpdateSummary *)endpointUpdateSummary {}
- (void)origoKeysDidFailToUpdateEndpoint:(NSError *)error {}
- (void)origoKeysDidTerminateEndpoint {}

@end
