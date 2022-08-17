////  MapController.h
//  Runner
//
//  Created by Mihail Varbanov on 8/17/22.
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
#import "FlutterCompletion.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MapController : UIViewController<FlutterCompletionHandler, GMSMapViewDelegate>

@property (nonatomic, strong) NSDictionary*         parameters;
@property (nonatomic, strong) FlutterCompletion     completionHandler;

@property (nonatomic, strong) GMSMapView*           gmsMapView;

- (instancetype)initWithParameters:(NSDictionary*)parameters completionHandler:(FlutterCompletion)completionHandler;

- (void)layoutSubViews;
@end

