//
//  MapPositionProviderController.h
//  Runner
//
//  Created by Mihail Varbanov on 7/11/19.
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

#import <UIKit/UIKit.h>
#import <MapsIndoors/MapsIndoors.h>
#import <Meridian/Meridian.h>

#import "MapController.h"

typedef NS_ENUM(NSInteger, MPPositionProviderSource) {
	MPPositionProviderSource_Meridian,
	MPPositionProviderSource_CoreLocation,
};


@interface MapPositionProviderController : MapController<MPMapControlDelegate, CLLocationManagerDelegate, MRLocationManagerDelegate, MPPositionProvider> {
	//	MPPositionProvider
	BOOL                                            _mpPositionProviderPreferAlwaysLocationPermission;
	BOOL                                            _mpPositionProviderLocationServicesActive;
	BOOL                                            _isRunning;
	MPPositionResult*                               _mpPositionResult;
	MPPositionProviderType                          _mpPositionProviderType;
	MPPositionProviderSource                        _mpPositionProviderSource;

	id<MPPositionProvider>                          _mpLastPositionProvider;
}

@property (nonatomic, strong) MPMapControl*         mpMapControl;
@property (nonatomic, strong) UILabel*              debugStatusLabel;

@property (nonatomic, strong) CLLocationManager*    clLocationManager;
@property (nonatomic, strong) CLLocation*           clLocation;
@property (nonatomic, strong) NSError*              clLocationError;

@property (nonatomic, strong) MREditorKey*          mrAppKey;
@property (nonatomic, strong) NSArray<MRMap *>*     mrMaps;
@property (nonatomic, strong) MRLocationManager*    mrLocationManager;
@property (nonatomic, strong) MRLocation*           mrLocation;
@property (nonatomic, strong) NSError*              mrLocationError;

@property (nonatomic, strong) NSTimer*              mrTimer;
@property (nonatomic)         NSTimeInterval        mrTimeoutInterval;
@property (nonatomic)         NSTimeInterval        mrSleepInterval;
@property (nonatomic)         NSUInteger            mrLocationUpdatesCount;
@property (nonatomic)         NSUInteger            mrLocationTimeoutsCount;

@property (nonatomic, weak)   id<MPPositionProviderDelegate>
                                                    mpPositionProviderDelegate;

- (void)layoutSubViews;

- (void)notifyLocationUpdate:(MPPositionResult*)positionResult source:(MPPositionProviderSource) source;
- (void)notifyLocationFail;
@end
